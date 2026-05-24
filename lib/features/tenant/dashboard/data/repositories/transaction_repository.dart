import '../../../../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final ApiClient _apiClient;

  TransactionRepository(this._apiClient);

  Future<List<TransactionModel>> getTransactions() async {
    final mockJson = {
      'data': [
        {
          'date': '5 Mei 2026',
          'invoiceNumber': 'INV-KSM-0526-001',
          'amount': 4500000.0,
          'status': 'failed',
          'propertyName': 'Premium Residence (Kamar 2A)',
        },
        {
          'date': '5 Apr 2026',
          'invoiceNumber': 'INV-KSM-0426-001',
          'amount': 4500000.0,
          'status': 'success',
          'propertyName': 'Premium Residence (Kamar 2A)',
        },
        {
          'date': '5 Mar 2026',
          'invoiceNumber': 'INV-KSM-0326-001',
          'amount': 4500000.0,
          'status': 'success',
          'propertyName': 'Premium Residence (Kamar 2A)',
        },
      ]
    };

    final response = await _apiClient.mockGet('/transactions', mockResponse: mockJson);
    final dataList = response['data'] as List;
    return dataList.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
