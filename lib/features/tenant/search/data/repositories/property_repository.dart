import '../../../../../core/services/mysql_service.dart';
import '../../domain/entities/property_entity.dart';
import '../models/property_model.dart';

class PropertyRepository {
  final MySqlService _mysqlService;

  PropertyRepository(this._mysqlService);

  Future<List<PropertyEntity>> getProperties() async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        'SELECT p.*, '
        '(SELECT COALESCE(MIN(r.price), 0.0) FROM rooms r WHERE r.property_id = p.id_int) AS min_price, '
        '(SELECT COALESCE(MAX(r.price), 0.0) FROM rooms r WHERE r.property_id = p.id_int) AS max_price, '
        '(SELECT COUNT(*) FROM rooms r WHERE r.property_id = p.id_int AND r.is_all_inclusive = 1) > 0 AS has_all_inclusive '
        'FROM properties p'
      );
      final list = <PropertyEntity>[];
      for (var row in results.rows) {
        list.add(PropertyModel(
          id: int.tryParse(row.colByName('id_int') ?? '0') ?? 0,
          ownerId: int.tryParse(row.colByName('owner_id_int') ?? '2') ?? 2,
          title: row.colByName('name') ?? '',
          location: row.colByName('district') ?? '',
          address: row.colByName('address') ?? '',
          minPrice: double.tryParse(row.colByName('min_price') ?? '0') ?? 0.0,
          maxPrice: double.tryParse(row.colByName('max_price') ?? '0') ?? 0.0,
          rating: double.tryParse(row.colByName('rating') ?? '0') ?? 0.0,
          imageUrl: row.colByName('image') ?? '',
          latitude: double.tryParse(row.colByName('latitude') ?? '0') ?? 0.0,
          longitude: double.tryParse(row.colByName('longitude') ?? '0') ?? 0.0,
          description: row.colByName('description') ?? '',
          hasAllInclusive: row.colByName('has_all_inclusive') == '1' || row.colByName('has_all_inclusive') == 'true',
        ));
      }
      return list;
    });
  }

  Future<bool> addReview({
    required int propertyId,
    required int userId,
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

      final insertResult = await conn.execute(
        'INSERT INTO reviews (property_id_int, user_id_int, rating, comment, date) '
        'VALUES (:propertyId, :userId, :rating, :comment, :dateStr)',
        {
          'propertyId': propertyId,
          'userId': userId,
          'rating': rating,
          'comment': comment,
          'dateStr': dateStr,
        },
      );

      if (insertResult.affectedRows > BigInt.zero) {
        // Recalculate average rating of the property
        await conn.execute(
          'UPDATE properties SET rating = '
          '(SELECT COALESCE(AVG(rating), 0.0) FROM reviews WHERE property_id_int = :propertyId) '
          'WHERE id_int = :propertyId',
          {'propertyId': propertyId},
        );
        return true;
      }
      return false;
    });
  }

  Future<List<Map<String, dynamic>>> getReviewsForProperty(int propertyId) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        'SELECT r.*, u.name as user_name FROM reviews r '
        'JOIN users u ON r.user_id_int = u.id_int '
        'WHERE r.property_id_int = :propertyId ORDER BY r.id_int DESC',
        {'propertyId': propertyId},
      );

      final list = <Map<String, dynamic>>[];
      for (var row in results.rows) {
        list.add({
          'id': int.parse(row.colByName('id_int')!),
          'property_id': int.parse(row.colByName('property_id_int')!),
          'user_id': int.parse(row.colByName('user_id_int')!),
          'rating': double.parse(row.colByName('rating')!),
          'comment': row.colByName('comment'),
          'date_str': row.colByName('date') ?? '',
          'user_name': row.colByName('user_name') ?? '',
        });
      }
      return list;
    });
  }

  Future<List<Map<String, dynamic>>> getReviewsForLandlordProperties(int landlordId) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        'SELECT r.*, u.name as user_name, p.name as property_title FROM reviews r '
        'JOIN users u ON r.user_id_int = u.id_int '
        'JOIN properties p ON r.property_id_int = p.id_int '
        'WHERE p.owner_id_int = :landlordId ORDER BY r.id_int DESC',
        {'landlordId': landlordId},
      );

      final list = <Map<String, dynamic>>[];
      for (var row in results.rows) {
        list.add({
          'id': int.parse(row.colByName('id_int')!),
          'property_id': int.parse(row.colByName('property_id_int')!),
          'user_id': int.parse(row.colByName('user_id_int')!),
          'rating': double.parse(row.colByName('rating')!),
          'comment': row.colByName('comment'),
          'date_str': row.colByName('date') ?? '',
          'user_name': row.colByName('user_name') ?? '',
          'property_title': row.colByName('property_title') ?? '',
        });
      }
      return list;
    });
  }
}
