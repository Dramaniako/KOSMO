import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';
import '../../data/models/landlord_stats_model.dart';
import '../../data/repositories/landlord_repository.dart';

final landlordRepositoryProvider = Provider<LandlordRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LandlordRepository(apiClient);
});

final landlordProvider = FutureProvider<LandlordStatsModel>((ref) async {
  final repository = ref.watch(landlordRepositoryProvider);
  return repository.getStats();
});
