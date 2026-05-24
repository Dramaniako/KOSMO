import '../../../../../core/network/api_client.dart';
import '../models/landlord_stats_model.dart';

class LandlordRepository {
  final ApiClient _apiClient;

  LandlordRepository(this._apiClient);

  Future<LandlordStatsModel> getStats() async {
    final mockJson = {
      'totalRevenue': 38500000.0,
      'revenueChange': '+12%',
      'totalUnitsLabel': '2 Unit',
      'occupancyRate': '86%',
      'residentsLabel': '13 Penghuni',
      'properties': [
        {
          'title': 'Premium Residence',
          'address': 'Jl. Merdeka No. 45, Jakarta Selatan',
          'totalRooms': 10,
          'occupiedRooms': 8,
          'imageUrl': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400',
        },
        {
          'title': 'KOSMO Hub Setiabudi',
          'address': 'Jl. Setiabudi Tengah No. 12, Jakarta',
          'totalRooms': 5,
          'occupiedRooms': 5,
          'imageUrl': 'https://images.unsplash.com/photo-1502672260266-1c1de2d96674?auto=format&fit=crop&q=80&w=400',
        }
      ]
    };

    final response = await _apiClient.mockGet('/landlord/stats', mockResponse: mockJson);
    return LandlordStatsModel.fromJson(response as Map<String, dynamic>);
  }
}
