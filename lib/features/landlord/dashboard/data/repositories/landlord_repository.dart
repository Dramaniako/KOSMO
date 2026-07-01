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
        '(SELECT COUNT(*) FROM rooms r WHERE r.property_id = p.id_int AND r.tenant_id IS NOT NULL) AS real_occupied_rooms, '
        '(SELECT COALESCE(MIN(r.price), 0.0) FROM rooms r WHERE r.property_id = p.id_int) AS min_price, '
        '(SELECT r.all_inclusive_bills FROM rooms r WHERE r.property_id = p.id_int LIMIT 1) AS first_room_bills '
        'FROM properties p WHERE p.owner_id_int = :owner_id',
        {'owner_id': ownerId},
      );
      final properties = <LandlordPropertyModel>[];
      int totalRoomsSum = 0;
      int occupiedRoomsSum = 0;
      
      for (var row in propResults.rows) {
        final propertyId = int.tryParse(row.colByName('id_int') ?? '0') ?? 0;
        final title = row.colByName('name') ?? '';
        final address = row.colByName('address') ?? '';
        final totalRooms = int.tryParse(row.colByName('totalRooms') ?? '0') ?? 0;
        // Use the real occupied count from rooms table
        final occupiedRooms = int.tryParse(row.colByName('real_occupied_rooms') ?? '0') ?? 0;
        final imageUrl = row.colByName('image') ?? '';
        final description = row.colByName('description') ?? '';
        final allInclusiveBills = row.colByName('first_room_bills') ?? '';
        final price = double.tryParse(row.colByName('min_price') ?? '0') ?? 0.0;
        
        totalRoomsSum += totalRooms;
        occupiedRoomsSum += occupiedRooms;

        // Sync occupied_rooms column in properties table to match rooms table
        await conn.execute(
          'UPDATE properties SET occupiedRooms = :occupied WHERE id_int = :id',
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

      // 2. Fetch transactions for revenue (using property_id foreign key)
      final transResults = await conn.execute(
        "SELECT SUM(t.amount) as total_rev FROM transactions t "
        "JOIN properties p ON t.property_id = p.id_int "
        "WHERE p.owner_id_int = :owner_id AND t.status = 'success'",
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
        "WHERE w.landlord_id_int = :owner_id AND w.status IN ('success', 'Selesai')",
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
      // 1. Insert the property (without price & billing)
      final result = await conn.execute(
        "INSERT INTO properties (owner_id_int, name, address, district, rating, latitude, longitude, totalRooms, occupiedRooms, image, description) "
        "VALUES (:owner_id, :title, :address, :location, :rating, :latitude, :longitude, :total_rooms, :occupied_rooms, :image_url, :description)",
        {
          'owner_id': ownerId,
          'title': title,
          'address': address,
          'location': location,
          'rating': 0.0,
          'latitude': latitude,
          'longitude': longitude,
          'total_rooms': totalRooms,
          'occupied_rooms': occupiedRooms,
          'image_url': imageUrl,
          'description': description,
        },
      );

      if (result.affectedRows > BigInt.zero) {
        // 2. Get the newly inserted property ID
        final idResult = await conn.execute('SELECT LAST_INSERT_ID() as new_id');
        final newPropertyId = int.parse(idResult.rows.first.colByName('new_id') ?? '0');

        if (newPropertyId > 0) {
          // 3. Auto-create rooms for the new property, saving default price & bills to rooms table
          for (int i = 1; i <= totalRooms; i++) {
            final roomNumber = 'Kamar ${100 + i}';
            await conn.execute(
              "INSERT INTO rooms (property_id, room_number, tenant_id, price, is_all_inclusive, all_inclusive_bills) "
              "VALUES (:propertyId, :roomNumber, NULL, :price, :isAllInclusive, :allInclusiveBills)",
              {
                'propertyId': newPropertyId,
                'roomNumber': roomNumber,
                'price': price,
                'isAllInclusive': isAllInclusive ? 1 : 0,
                'allInclusiveBills': allInclusiveBills,
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
    required String imageUrl,
    required int totalRooms,
    required String description,
  }) async {
    return _mysqlService.run((conn) async {
      // 1. Update the property details
      final result = await conn.execute(
        "UPDATE properties SET name = :title, address = :address, district = :location, "
        "image = :image_url, totalRooms = :total_rooms, description = :description WHERE id_int = :id",
        {
          'id': id,
          'title': title,
          'address': address,
          'location': location,
          'image_url': imageUrl,
          'total_rooms': totalRooms,
          'description': description,
        },
      );

      // 2. Adjust total rooms in the database
      final countResult = await conn.execute(
        "SELECT COUNT(*) as cnt FROM rooms WHERE property_id = :propertyId",
        {"propertyId": id},
      );
      final currentCount = int.parse(countResult.rows.first.colByName('cnt') ?? '0');

      if (totalRooms > currentCount) {
        // Fetch default pricing/billing from first room of this property
        double defaultPrice = 1500000.0;
        int defaultIsAllInclusive = 1;
        String? defaultBills = 'Listrik,Air';
        final firstRoom = await conn.execute(
          "SELECT price, is_all_inclusive, all_inclusive_bills FROM rooms WHERE property_id = :id LIMIT 1",
          {"id": id},
        );
        if (firstRoom.rows.isNotEmpty) {
          defaultPrice = double.tryParse(firstRoom.rows.first.colByName('price') ?? '1500000.0') ?? 1500000.0;
          defaultIsAllInclusive = int.tryParse(firstRoom.rows.first.colByName('is_all_inclusive') ?? '1') ?? 1;
          defaultBills = firstRoom.rows.first.colByName('all_inclusive_bills');
        }

        // Add vacant rooms
        for (int i = currentCount + 1; i <= totalRooms; i++) {
          final roomNumber = 'Kamar ${100 + i}';
          await conn.execute(
            "INSERT INTO rooms (property_id, room_number, tenant_id, price, is_all_inclusive, all_inclusive_bills) "
            "VALUES (:propertyId, :roomNumber, NULL, :price, :isAllInclusive, :allInclusiveBills)",
            {
              'propertyId': id,
              'roomNumber': roomNumber,
              'price': defaultPrice,
              'isAllInclusive': defaultIsAllInclusive,
              'allInclusiveBills': defaultBills,
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
        "UPDATE properties SET occupiedRooms = "
        "(SELECT COUNT(*) FROM rooms WHERE property_id = :id AND tenant_id IS NOT NULL) "
        "WHERE id_int = :id",
        {"id": id},
      );

      return true;
    });
  }

  Future<List<RoomModel>> getRoomsForProperty(int propertyId) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        "SELECT r.*, u.name as tenant_name FROM rooms r "
        "LEFT JOIN users u ON r.tenant_id = u.id_int "
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
          price: double.tryParse(row.colByName('price') ?? '0') ?? 0.0,
          isAllInclusive: row.colByName('is_all_inclusive') == '1',
          allInclusiveBills: row.colByName('all_inclusive_bills'),
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
    required double price,
    required bool isAllInclusive,
    String? allInclusiveBills,
  }) async {
    return _mysqlService.run((conn) async {
      final result = await conn.execute(
        "UPDATE rooms SET room_number = :roomNumber, description = :description, image_url = :image_url, "
        "price = :price, is_all_inclusive = :isAllInclusive, all_inclusive_bills = :allInclusiveBills WHERE id = :roomId",
        {
          "roomId": roomId,
          "roomNumber": roomNumber,
          "description": description,
          "image_url": imageUrl,
          "price": price,
          "isAllInclusive": isAllInclusive ? 1 : 0,
          "allInclusiveBills": allInclusiveBills,
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
    required double price,
    required bool isAllInclusive,
    String? allInclusiveBills,
  }) async {
    return _mysqlService.run((conn) async {
      final insertResult = await conn.execute(
        "INSERT INTO rooms (property_id, room_number, tenant_id, description, image_url, price, is_all_inclusive, all_inclusive_bills) "
        "VALUES (:propertyId, :roomNumber, NULL, :description, :imageUrl, :price, :isAllInclusive, :allInclusiveBills)",
        {
          "propertyId": propertyId,
          "roomNumber": roomNumber,
          "description": description,
          "imageUrl": imageUrl,
          "price": price,
          "isAllInclusive": isAllInclusive ? 1 : 0,
          "allInclusiveBills": allInclusiveBills,
        },
      );
      if (insertResult.affectedRows == BigInt.zero) return false;

      await conn.execute(
        "UPDATE properties SET totalRooms = (SELECT COUNT(*) FROM rooms WHERE property_id = :propertyId) "
        "WHERE id_int = :propertyId",
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
        "UPDATE properties SET totalRooms = (SELECT COUNT(*) FROM rooms WHERE property_id = :propertyId) "
        "WHERE id_int = :propertyId",
        {"propertyId": propertyId},
      );
      return true;
    });
  }

  /// Verify user password against the database hash
  Future<bool> verifyPassword(int userId, String password) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        'SELECT password FROM users WHERE id_int = :id',
        {'id': userId},
      );
      if (results.rows.isEmpty) return false;

      final storedHash = results.rows.first.colByName('password') ?? '';
      final inputHash = sha256.convert(utf8.encode(password)).toString();
      return storedHash == inputHash || storedHash == password;
    });
  }

  /// Delete a property and its associated rooms (CASCADE handles rooms)
  Future<bool> deleteProperty(int propertyId) async {
    return _mysqlService.run((conn) async {
      // Rooms are deleted automatically via ON DELETE CASCADE
      final result = await conn.execute(
        'DELETE FROM properties WHERE id_int = :id',
        {'id': propertyId},
      );
      return result.affectedRows > BigInt.zero;
    });
  }

  /// Get withdrawals for a landlord
  Future<List<WithdrawalModel>> getWithdrawals(int landlordId) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        'SELECT * FROM withdrawals WHERE landlord_id_int = :landlordId ORDER BY id_int DESC',
        {'landlordId': landlordId},
      );
      final withdrawals = <WithdrawalModel>[];
      for (var row in results.rows) {
        withdrawals.add(WithdrawalModel.fromJson({
          'id': int.parse(row.colByName('id_int')!),
          'landlord_id': int.parse(row.colByName('landlord_id_int')!),
          'amount': double.parse(row.colByName('amount')!),
          'bank_name': row.colByName('bankName') ?? '',
          'account_number': row.colByName('accountNumber') ?? '',
          'date_str': row.colByName('date') ?? '',
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
        'INSERT INTO withdrawals (landlord_id_int, amount, bankName, accountNumber, date, status) '
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

  /// Get all tenants renting properties from this landlord
  Future<List<Map<String, dynamic>>> getTenantsForLandlord(int landlordId) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        "SELECT r.id as room_id, r.room_number, u.id_int as tenant_id, u.name as tenant_name, "
        "u.email as tenant_email, u.phone as phone_number, u.gender, u.age, u.address as tenant_address, p.name as property_title, p.id_int as property_id "
        "FROM rooms r "
        "JOIN properties p ON r.property_id = p.id_int "
        "JOIN users u ON r.tenant_id = u.id_int "
        "WHERE p.owner_id_int = :landlordId",
        {"landlordId": landlordId},
      );
      final list = <Map<String, dynamic>>[];
      for (var row in results.rows) {
        list.add({
          'room_id': int.parse(row.colByName('room_id')!),
          'room_number': row.colByName('room_number') ?? '',
          'tenant_id': int.parse(row.colByName('tenant_id')!),
          'tenant_name': row.colByName('tenant_name') ?? '',
          'tenant_email': row.colByName('tenant_email') ?? '',
          'phone_number': row.colByName('phone_number') ?? '',
          'gender': row.colByName('gender') ?? '',
          'age': int.tryParse(row.colByName('age') ?? '') ?? 0,
          'tenant_address': row.colByName('tenant_address') ?? '',
          'property_title': row.colByName('property_title') ?? '',
          'property_id': int.parse(row.colByName('property_id')!),
        });
      }
      return list;
    });
  }

  /// Add landlord review for a tenant
  Future<bool> addTenantReview({
    required int landlordId,
    required int tenantId,
    required double rating,
    required String comment,
  }) async {
    return _mysqlService.run((conn) async {
      final now = DateTime.now();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
      final result = await conn.execute(
        "INSERT INTO reviews_tenants (landlord_id, tenant_id, rating, comment, date_str) "
        "VALUES (:landlordId, :tenantId, :rating, :comment, :dateStr)",
        {
          "landlordId": landlordId,
          "tenantId": tenantId,
          "rating": rating,
          "comment": comment,
          "dateStr": dateStr,
        },
      );
      return result.affectedRows > BigInt.zero;
    });
  }
}
