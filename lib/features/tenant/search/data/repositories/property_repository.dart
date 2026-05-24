import '../../../../../core/network/api_client.dart';
import '../../domain/entities/property_entity.dart';
import '../models/property_model.dart';

class PropertyRepository {
  final ApiClient _apiClient;

  PropertyRepository(this._apiClient);

  Future<List<PropertyEntity>> getProperties() async {
    final mockJson = {
      'data': [
        {
          'title': 'Kos Eksklusif Mawar',
          'location': 'Jakarta Selatan',
          'price': 2500000.0,
          'rating': 4.8,
          'isAllInclusive': true,
          'imageUrl': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400',
          'latitude': -6.2442,
          'longitude': 106.7982,
        },
        {
          'title': 'Kos Mahasiswa UI',
          'location': 'Depok',
          'price': 1500000.0,
          'rating': 4.5,
          'isAllInclusive': false,
          'imageUrl': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400',
          'latitude': -6.3680,
          'longitude': 106.8320,
        },
        {
          'title': 'Premium Residence',
          'location': 'Jakarta Pusat',
          'price': 4500000.0,
          'rating': 4.9,
          'isAllInclusive': true,
          'imageUrl': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400',
          'latitude': -6.2088,
          'longitude': 106.8456,
        },
      ]
    };

    final response = await _apiClient.mockGet('/properties', mockResponse: mockJson);
    final dataList = response['data'] as List;
    return dataList.map((item) => PropertyModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
