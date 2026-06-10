import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../../../core/services/mysql_service.dart';
import '../../../../tenant/search/data/models/room_model.dart';
import '../models/landlord_property_model.dart';
import '../models/landlord_stats_model.dart';
import '../models/withdrawal_model.dart';

class LandlordRepository {
  final MySqlService _mysqlService;

  LandlordRepository(this._mysqlService);

  Future<LandlordStatsModel> getStats(int ownerId) async {
    return _mysqlService.run((conn) async {
      // 1. Fetch properties with occupied_rooms derived from rooms table
      final propResults = await conn.execute(
        'SELECT p.*, '
        '(SELECT COUNT(*) FROM rooms r WHERE r.property_id = p.id AND r.tenant_id IS NOT NULL) AS real_occupied_rooms '
        'FROM properties p WHERE p.owner_id = :owner_id',
        {'owner_id': ownerId},
      );
      final properties = <LandlordPropertyModel>[];
      int totalRoomsSum = 0;
      int occupiedRoomsSum = 0;
      
      for (var row in propResults.rows) {
        final propertyId = int.tryParse(row.colByName('id') ?? '0') ?? 0;
        final title = row.colByName('title') ?? '';
        final address = row.colByName('address') ?? '';
        final totalRooms = int.tryParse(row.colByName('total_rooms') ?? '0') ?? 0;
        // Use the real occupied count from rooms table
        final occupiedRooms = int.tryParse(row.colByName('real_occupied_rooms') ?? '0') ?? 0;
        final imageUrl = row.colByName('image_url') ?? '';
        final description = row.colByName('description') ?? '';
        final allInclusiveBills = row.colByName('all_inclusive_bills') ?? '';
        final price = double.tryParse(row.colByName('price') ?? '0') ?? 0.0;
        
        totalRoomsSum += totalRooms;
        occupiedRoomsSum += occupiedRooms;

        // Sync occupied_rooms column in properties table to match rooms table
        await conn.execute(
          'UPDATE properties SET occupied_rooms = :occupied WHERE id = :id',
          {'occupied': occupiedRooms, 'id': propertyId},
        );
        
        properties.add(LandlordPropertyModel(
          id: propertyId,
          title: title,
          address: address,
          totalRooms: totalRooms,
          occupiedRooms: occupiedRooms,
          imageUrl: imageUrl,
          description: description,
          allInclusiveBills: allInclusiveBills,
          price: price,
        ));
      }

      // 2. Fetch transactions for revenue
      final transResults = await conn.execute(
        "SELECT SUM(t.amount) as total_rev FROM transactions t "
        "JOIN properties p ON t.property_name LIKE CONCAT(p.title, '%') "
        "WHERE p.owner_id = :owner_id AND t.status = 'success'",
        {'owner_id': ownerId},
      );
      double totalRevenue = 0.0;
      if (transResults.rows.isNotEmpty) {
        final totalRevStr = transResults.rows.first.colByName('total_rev');
        if (totalRevStr != null) {
          totalRevenue = double.tryParse(totalRevStr) ?? 0.0;
        }
      }

      // 2b. Fetch withdrawals for totalWithdrawn
      final withdrawResults = await conn.execute(
        "SELECT SUM(w.amount) as total_withdrawn FROM withdrawals w "
        "WHERE w.landlord_id = :owner_id AND w.status = 'success'",
        {'owner_id': ownerId},
      );
      double totalWithdrawn = 0.0;
      if (withdrawResults.rows.isNotEmpty) {
        final totalWithdrawnStr = withdrawResults.rows.first.colByName('total_withdrawn');
        if (totalWithdrawnStr != null) {
          totalWithdrawn = double.tryParse(totalWithdrawnStr) ?? 0.0;
        }
      }
      double balance = totalRevenue - totalWithdrawn;

      // Calculate occupancy rate
      double occupancyPercent = 0;
      if (totalRoomsSum > 0) {
        occupancyPercent = (occupiedRoomsSum / totalRoomsSum) * 100;
      }

      return LandlordStatsModel(
        totalRevenue: totalRevenue,
        totalWithdrawn: totalWithdrawn,
        balance: balance,
        revenueChange: '+12%',
        totalUnitsLabel: '${properties.length} Unit',
        occupancyRate: '${occupancyPercent.round()}%',
        residentsLabel: '$occupiedRoomsSum Penghuni',
        properties: properties,
      );
    });
  }

  Future<bool> addProperty({
    required int ownerId,
    required String title,
    required String address,
    required String location,
    required double price,
    required double latitude,
    required double longitude,
    required int totalRooms,
    required int occupiedRooms,
    required String imageUrl,
    required bool isAllInclusive,
    required String description,
    String? allInclusiveBills,
  }) async {
    return _mysqlService.run((conn) async {
      // 1. Insert the property
      final result = await conn.execute(
        "INSERT INTO properties (owner_id, title, address, location, price, rating, latitude, longitude, total_rooms, occupied_rooms, image_url, is_all_inclusive, description, all_inclusive_bills) "
        "VALUES (:owner_id, :title, :address, :location, :price, :rating, :latitude, :longitude, :total_rooms, :occupied_rooms, :image_url, :is_all_inclusive, :description, :all_inclusive_bills)",
        {
          'owner_id': ownerId,
          'title': title,
          'address': address,
          'location': location,
          'price': price,
          'rating': 0.0,
          'latitude': latitude,
          'longitude': longitude,
          'total_rooms': totalRooms,
          'occupied_rooms': occupiedRooms,
          'image_url': imageUrl,
          'is_all_inclusive': isAllInclusive ? 1 : 0,
          'description': description,
          'all_inclusive_bills': allInclusiveBills,
        },
      );

      if (result.affectedRows > BigInt.zero) {
        // 2. Get the newly inserted property ID
        final idResult = await conn.execute('SELECT LAST_INSERT_ID() as new_id');
        final newPropertyId = int.parse(idResult.rows.first.colByName('new_id') ?? '0');

        if (newPropertyId > 0) {
          // 3. Auto-create rooms for the new property
          for (int i = 1; i <= totalRooms; i++) {
            final roomNumber = 'Kamar ${100 + i}';
            await conn.execute(
              "INSERT INTO rooms (property_id, room_number, tenant_id) VALUES (:propertyId, :roomNumber, NULL)",
              {
                'propertyId': newPropertyId,
                'roomNumber': roomNumber,
              },
            );
          }
        }
        return true;
      }
      return false;
    });
  }

  Future<bool> editProperty({
    required int id,
    required String title,
    required String address,
    required String location,
    required double price,
    required String imageUrl,
    required bool isAllInclusive,
    required int totalRooms,
    required String description,
    String? allInclusiveBills,
  }) async {
    return _mysqlService.run((conn) async {
      // 1. Update the property details
      final result = await conn.execute(
        "UPDATE properties SET title = :title, address = :address, location = :location, price = :price, "
        "image_url = :image_url, is_all_inclusive = :is_all_inclusive, total_rooms = :total_rooms, "
        "description = :description, all_inclusive_bills = :all_inclusive_bills WHERE id = :id",
        {
          'id': id,
          'title': title,
          'address': address,
          'location': location,
          'price': price,
          'image_url': imageUrl,
          'is_all_inclusive': isAllInclusive ? 1 : 0,
          'total_rooms': totalRooms,
          'description': description,
          'all_inclusive_bills': allInclusiveBills,
        },
      );

      // 2. Adjust total rooms in the database
      final countResult = await conn.execute(
        "SELECT COUNT(*) as cnt FROM rooms WHERE property_id = :propertyId",
        {"propertyId": id},
      );
      final currentCount = int.parse(countResult.rows.first.colByName('cnt') ?? '0');

      if (totalRooms > currentCount) {
        // Add vacant rooms
        for (int i = currentCount + 1; i <= totalRooms; i++) {
          final roomNumber = 'Kamar ${100 + i}';
          await conn.execute(
            "INSERT INTO rooms (property_id, room_number, tenant_id) VALUES (:propertyId, :roomNumber, NULL)",
            {
              'propertyId': id,
              'roomNumber': roomNumber,
            },
          );
        }
      } else if (totalRooms < currentCount) {
        // Delete unoccupied rooms from highest room number down to match totalRooms
        final roomsToDelete = await conn.execute(
          "SELECT id FROM rooms WHERE property_id = :propertyId AND tenant_id IS NULL ORDER BY room_number DESC",
          {"propertyId": id},
        );

        int toDeleteCount = currentCount - totalRooms;
        for (var row in roomsToDelete.rows) {
          if (toDeleteCount <= 0) break;
          final roomId = int.parse(row.colByName('id')!);
          await conn.execute(
            "DELETE FROM rooms WHERE id = :roomId",
            {"roomId": roomId},
          );
          toDeleteCount--;
        }
      }

      // 3. Recalculate occupied_rooms
      await conn.execute(
        "UPDATE properties SET occupied_rooms = "
        "(SELECT COUNT(*) FROM rooms WHERE property_id = :id AND tenant_id IS NOT NULL) "
        "WHERE id = :id",
        {"id": id},
      );

      return true;
    });
  }

  Future<List<RoomModel>> getRoomsForProperty(int propertyId) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        "SELECT r.*, u.name as tenant_name FROM rooms r "
        "LEFT JOIN users u ON r.tenant_id = u.id "
        "WHERE r.property_id = :propertyId ORDER BY r.room_number ASC",
        {"propertyId": propertyId},
      );
      
      final list = <RoomModel>[];
      for (var row in results.rows) {
        list.add(RoomModel(
          id: int.parse(row.colByName('id')!),
          propertyId: int.parse(row.colByName('property_id')!),
          roomNumber: row.colByName('room_number') ?? '',
          tenantId: row.colByName('tenant_id') != null ? int.parse(row.colByName('tenant_id')!) : null,
          description: row.colByName('description') ?? '',
          imageUrl: row.colByName('image_url') ?? '',
          tenantName: row.colByName('tenant_name'),
        ));
      }
      return list;
    });
  }

  Future<bool> updateRoom({
    required int roomId,
    required String roomNumber,
    required String description,
    required String imageUrl,
  }) async {
    return _mysqlService.run((conn) async {
      final result = await conn.execute(
        "UPDATE rooms SET room_number = :roomNumber, description = :description, image_url = :image_url WHERE id = :roomId",
        {
          "roomId": roomId,
          "roomNumber": roomNumber,
          "description": description,
          "image_url": imageUrl,
        },
      );
      return result.affectedRows > BigInt.zero;
    });
  }

  Future<bool> addRoom({
    required int propertyId,
    required String roomNumber,
    required String description,
    required String imageUrl,
  }) async {
    return _mysqlService.run((conn) async {
      final insertResult = await conn.execute(
        "INSERT INTO rooms (property_id, room_number, tenant_id, description, image_url) "
        "VALUES (:propertyId, :roomNumber, NULL, :description, :imageUrl)",
        {
          "propertyId": propertyId,
          "roomNumber": roomNumber,
          "description": description,
          "imageUrl": imageUrl,
        },
      );
      if (insertResult.affectedRows == BigInt.zero) return false;

      await conn.execute(
        "UPDATE properties SET total_rooms = (SELECT COUNT(*) FROM rooms WHERE property_id = :propertyId) "
        "WHERE id = :propertyId",
        {"propertyId": propertyId},
      );
      return true;
    });
  }

  Future<bool> deleteRoom({
    required int roomId,
    required int propertyId,
  }) async {
    return _mysqlService.run((conn) async {
      final deleteResult = await conn.execute(
        "DELETE FROM rooms WHERE id = :roomId",
        {"roomId": roomId},
      );
      if (deleteResult.affectedRows == BigInt.zero) return false;

      await conn.execute(
        "UPDATE properties SET total_rooms = (SELECT COUNT(*) FROM rooms WHERE property_id = :propertyId) "
        "WHERE id = :propertyId",
        {"propertyId": propertyId},
      );
      return true;
    });
  }

  /// Verify user password against the database hash
  Future<bool> verifyPassword(int userId, String password) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        'SELECT password_hash FROM users WHERE id = :id',
        {'id': userId},
      );
      if (results.rows.isEmpty) return false;

      final storedHash = results.rows.first.colByName('password_hash') ?? '';
      final inputHash = sha256.convert(utf8.encode(password)).toString();
      return storedHash == inputHash;
    });
  }

  /// Delete a property and its associated rooms (CASCADE handles rooms)
  Future<bool> deleteProperty(int propertyId) async {
    return _mysqlService.run((conn) async {
      // Rooms are deleted automatically via ON DELETE CASCADE
      final result = await conn.execute(
        'DELETE FROM properties WHERE id = :id',
        {'id': propertyId},
      );
      return result.affectedRows > BigInt.zero;
    });
  }

  /// Get withdrawals for a landlord
  Future<List<WithdrawalModel>> getWithdrawals(int landlordId) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        'SELECT * FROM withdrawals WHERE landlord_id = :landlordId ORDER BY id DESC',
        {'landlordId': landlordId},
      );
      final withdrawals = <WithdrawalModel>[];
      for (var row in results.rows) {
        withdrawals.add(WithdrawalModel.fromJson({
          'id': int.parse(row.colByName('id')!),
          'landlord_id': int.parse(row.colByName('landlord_id')!),
          'amount': double.parse(row.colByName('amount')!),
          'bank_name': row.colByName('bank_name') ?? '',
          'account_number': row.colByName('account_number') ?? '',
          'date_str': row.colByName('date_str') ?? '',
          'status': row.colByName('status') ?? '',
        }));
      }
      return withdrawals;
    });
  }

  /// Request a withdrawal
  Future<bool> requestWithdrawal({
    required int landlordId,
    required double amount,
    required String bankName,
    required String accountNumber,
  }) async {
    return _mysqlService.run((conn) async {
      final now = DateTime.now();
      // Format date in Indonesian style, e.g. "4 Jun 2026"
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
      
      final result = await conn.execute(
        'INSERT INTO withdrawals (landlord_id, amount, bank_name, account_number, date_str, status) '
        'VALUES (:landlordId, :amount, :bankName, :accountNumber, :dateStr, :status)',
        {
          'landlordId': landlordId,
          'amount': amount,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'dateStr': dateStr,
          'status': 'success',
        },
      );
      return result.affectedRows > BigInt.zero;
    });
  }
}
