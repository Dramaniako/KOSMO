import 'landlord_property_model.dart';
import '../../../../tenant/dashboard/data/models/transaction_model.dart';

class LandlordStatsModel {
  final double totalRevenue;
  final double totalWithdrawn;
  final double balance;
  final String revenueChange;
  final String totalUnitsLabel;
  final String occupancyRate;
  final String residentsLabel;
  final List<LandlordPropertyModel> properties;

  const LandlordStatsModel({
    required this.totalRevenue,
    required this.totalWithdrawn,
    required this.balance,
    required this.revenueChange,
    required this.totalUnitsLabel,
    required this.occupancyRate,
    required this.residentsLabel,
    required this.properties,
  });

  factory LandlordStatsModel.fromJson(Map<String, dynamic> json) {
    final list = json['properties'] as List;
    final parsedProperties = list.map((item) => LandlordPropertyModel.fromJson(item as Map<String, dynamic>)).toList();

    return LandlordStatsModel(
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      revenueChange: json['revenueChange'] as String,
      totalUnitsLabel: json['totalUnitsLabel'] as String,
      occupancyRate: json['occupancyRate'] as String,
      residentsLabel: json['residentsLabel'] as String,
      properties: parsedProperties,
    );
  }
}

class LandlordDashboardData {
  final LandlordStatsModel stats;
  final List<Map<String, dynamic>> tenants;
  final List<Map<String, dynamic>> reviews;
  final List<TransactionModel> transactions;

  const LandlordDashboardData({
    required this.stats,
    required this.tenants,
    required this.reviews,
    required this.transactions,
  });
}
