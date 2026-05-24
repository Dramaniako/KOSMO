import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/api_client.dart';
import '../../data/repositories/property_repository.dart';
import '../../domain/entities/property_entity.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PropertyRepository(apiClient);
});

final searchProvider = FutureProvider<List<PropertyEntity>>((ref) async {
  final repository = ref.watch(propertyRepositoryProvider);
  return repository.getProperties();
});
