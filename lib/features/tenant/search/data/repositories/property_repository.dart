import '../../../../../core/services/mysql_service.dart';
import '../../domain/entities/property_entity.dart';
import '../models/property_model.dart';

class PropertyRepository {
  final MySqlService _mysqlService;

  PropertyRepository(this._mysqlService);

  Future<List<PropertyEntity>> getProperties() async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute('SELECT * FROM properties');
      final list = <PropertyEntity>[];
      for (var row in results.rows) {
        list.add(PropertyModel(
          id: int.tryParse(row.colByName('id') ?? '0') ?? 0,
          ownerId: int.tryParse(row.colByName('owner_id') ?? '2') ?? 2,
          title: row.colByName('title') ?? '',
          location: row.colByName('location') ?? '',
          address: row.colByName('address') ?? '',
          price: double.tryParse(row.colByName('price') ?? '0') ?? 0.0,
          rating: double.tryParse(row.colByName('rating') ?? '0') ?? 0.0,
          isAllInclusive: row.colByName('is_all_inclusive') == '1',
          allInclusiveBills: row.colByName('all_inclusive_bills'),
          imageUrl: row.colByName('image_url') ?? '',
          latitude: double.tryParse(row.colByName('latitude') ?? '0') ?? 0.0,
          longitude: double.tryParse(row.colByName('longitude') ?? '0') ?? 0.0,
          description: row.colByName('description') ?? '',
        ));
      }
      return list;
    });
  }
}
