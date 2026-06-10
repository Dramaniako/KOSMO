import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/mysql_service.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/landlord_stats_model.dart';
import '../../data/repositories/landlord_repository.dart';

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
