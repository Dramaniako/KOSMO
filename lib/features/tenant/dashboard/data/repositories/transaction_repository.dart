import '../../../../../core/services/mysql_service.dart';
import '../../presentation/widgets/transaction_card.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final MySqlService _mysqlService;

  TransactionRepository(this._mysqlService);

  Future<List<TransactionModel>> getTransactions([int? userId]) async {
    return _mysqlService.run((conn) async {
      final results = userId != null
          ? await conn.execute('SELECT * FROM transactions WHERE user_id = :userId ORDER BY id DESC', {'userId': userId})
          : await conn.execute('SELECT * FROM transactions ORDER BY id DESC');
      
      final list = <TransactionModel>[];
      for (var row in results.rows) {
        list.add(TransactionModel(
          date: row.colByName('date_str') ?? '',
          invoiceNumber: row.colByName('invoice_number') ?? '',
          amount: double.tryParse(row.colByName('amount') ?? '0') ?? 0.0,
          status: _parseTransactionStatus(row.colByName('status') ?? 'pending'),
          propertyName: row.colByName('property_name') ?? '',
          userId: row.colByName('user_id') != null ? int.tryParse(row.colByName('user_id')!) : null,
          transactionType: row.colByName('transaction_type') ?? 'rental',
        ));
      }
      return list;
    });
  }

  TransactionStatus _parseTransactionStatus(String statusStr) {
    switch (statusStr) {
      case 'success':
        return TransactionStatus.success;
      case 'failed':
        return TransactionStatus.failed;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }

  Future<bool> saveTransaction(TransactionModel transaction, [int? userId, int? roomId]) async {
    return _mysqlService.run((conn) async {
      String statusStr = 'pending';
      if (transaction.status == TransactionStatus.success) statusStr = 'success';
      if (transaction.status == TransactionStatus.failed) statusStr = 'failed';

      final result = await conn.execute(
        "INSERT INTO transactions (invoice_number, date_str, amount, status, property_name, user_id, transaction_type) "
        "VALUES (:invoice_number, :date_str, :amount, :status, :property_name, :user_id, :transaction_type)",
        {
          'invoice_number': transaction.invoiceNumber,
          'date_str': transaction.date,
          'amount': transaction.amount,
          'status': statusStr,
          'property_name': transaction.propertyName,
          'user_id': userId,
          'transaction_type': transaction.transactionType,
        },
      );

      if (statusStr == 'success' && userId != null) {
        // Strip room suffix in propertyName to find actual property title if propertyName contains " ("
        var propTitle = transaction.propertyName;
        if (propTitle.contains(' (')) {
          propTitle = propTitle.split(' (').first;
        }

        final propResult = await conn.execute(
          "SELECT id FROM properties WHERE title = :title LIMIT 1",
          {"title": propTitle},
        );
        if (propResult.rows.isNotEmpty) {
          final propertyId = int.parse(propResult.rows.first.colAt(0)!);

          // Find if user already has a room in this property
          final existingRoom = await conn.execute(
            "SELECT id FROM rooms WHERE property_id = :propertyId AND tenant_id = :userId LIMIT 1",
            {"propertyId": propertyId, "userId": userId},
          );

          if (existingRoom.rows.isEmpty) {
            if (roomId != null) {
              // Occupy the exact room selected by the user
              await conn.execute(
                "UPDATE rooms SET tenant_id = :userId WHERE id = :roomId",
                {"userId": userId, "roomId": roomId},
              );
            } else {
              // Fallback to find a vacant room in this property
              final vacantRoom = await conn.execute(
                "SELECT id FROM rooms WHERE property_id = :propertyId AND tenant_id IS NULL LIMIT 1",
                {"propertyId": propertyId},
              );

              if (vacantRoom.rows.isNotEmpty) {
                final vacantRoomId = int.parse(vacantRoom.rows.first.colByName('id')!);
                await conn.execute(
                  "UPDATE rooms SET tenant_id = :userId WHERE id = :roomId",
                  {"userId": userId, "roomId": vacantRoomId},
                );
              } else {
                // No vacant room found, let's create a new room dynamically
                final countResult = await conn.execute(
                  "SELECT COUNT(*) FROM rooms WHERE property_id = :propertyId",
                  {"propertyId": propertyId},
                );
                final count = int.parse(countResult.rows.first.colAt(0) ?? '0');
                final newRoomNumber = "Kamar ${count + 101}";
                await conn.execute(
                  "INSERT INTO rooms (property_id, room_number, tenant_id) VALUES (:propertyId, :roomNumber, :userId)",
                  {
                    "propertyId": propertyId,
                    "roomNumber": newRoomNumber,
                    "userId": userId,
                  },
                );
              }
            }

            // Sync occupied_rooms in properties table from rooms table
            await conn.execute(
              "UPDATE properties SET occupied_rooms = "
              "(SELECT COUNT(*) FROM rooms WHERE property_id = :propertyId AND tenant_id IS NOT NULL) "
              "WHERE id = :propertyId",
              {"propertyId": propertyId},
            );
          }
        }
      }

      return result.affectedRows > BigInt.zero;
    });
  }

  Future<bool> payArrearsTransaction(String invoiceNumber) async {
    return _mysqlService.run((conn) async {
      final result = await conn.execute(
        "UPDATE transactions SET status = 'success' WHERE invoice_number = :invoiceNumber",
        {"invoiceNumber": invoiceNumber},
      );
      return result.affectedRows > BigInt.zero;
    });
  }
}
