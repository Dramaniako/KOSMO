import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/mysql_service.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/landlord_stats_model.dart';
import '../../data/repositories/landlord_repository.dart';

import '../../../../tenant/dashboard/presentation/providers/transaction_provider.dart';
import '../../../../tenant/dashboard/data/models/transaction_model.dart';
import '../../../../tenant/search/data/repositories/property_repository.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';

final landlordRepositoryProvider = Provider<LandlordRepository>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  return LandlordRepository(mysqlService);
});

// Single combined dashboard data provider to execute all queries inside 1 database connection
final landlordDashboardProvider = FutureProvider<LandlordDashboardData>((ref) async {
  final repository = ref.watch(landlordRepositoryProvider);
  final authState = ref.watch(authProvider);
  final landlordId = authState.user?.id ?? 2; // Default to 2 if not logged in
  return repository.getDashboardData(landlordId);
});

final landlordProvider = FutureProvider<LandlordStatsModel>((ref) async {
  ref.onDispose(() {
    ref.invalidate(landlordDashboardProvider);
  });
  final dashboard = await ref.watch(landlordDashboardProvider.future);
  return dashboard.stats;
});

final landlordTenantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.onDispose(() {
    ref.invalidate(landlordDashboardProvider);
  });
  final dashboard = await ref.watch(landlordDashboardProvider.future);
  return dashboard.tenants;
});

final landlordReviewsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.onDispose(() {
    ref.invalidate(landlordDashboardProvider);
  });
  final dashboard = await ref.watch(landlordDashboardProvider.future);
  return dashboard.reviews;
});

final landlordTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  ref.onDispose(() {
    ref.invalidate(landlordDashboardProvider);
  });
  final dashboard = await ref.watch(landlordDashboardProvider.future);
  return dashboard.transactions;
});
