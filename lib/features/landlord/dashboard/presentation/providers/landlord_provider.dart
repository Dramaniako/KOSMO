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

final landlordProvider = FutureProvider<LandlordStatsModel>((ref) async {
  final repository = ref.watch(landlordRepositoryProvider);
  final authState = ref.watch(authProvider);
  final ownerId = authState.user?.id ?? 2; // Default to 2 (Landlord Kosmo) if not logged in
  return repository.getStats(ownerId);
});

final landlordTenantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(landlordRepositoryProvider);
  final authState = ref.watch(authProvider);
  final landlordId = authState.user?.id ?? 2;
  return repository.getTenantsForLandlord(landlordId);
});

final landlordReviewsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final propRepository = ref.watch(propertyRepositoryProvider);
  final authState = ref.watch(authProvider);
  final landlordId = authState.user?.id ?? 2;
  return propRepository.getReviewsForLandlordProperties(landlordId);
});

final landlordTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final txRepository = ref.watch(transactionRepositoryProvider);
  final authState = ref.watch(authProvider);
  final landlordId = authState.user?.id ?? 2;
  return txRepository.getReceivedPaymentsForLandlord(landlordId);
});
