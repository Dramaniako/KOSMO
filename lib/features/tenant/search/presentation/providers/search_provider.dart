import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/services/mysql_service.dart';
import '../../data/repositories/property_repository.dart';
import '../../domain/entities/property_entity.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  return PropertyRepository(mysqlService);
});

class SearchFilters {
  final String query;
  final String selectedCity;
  final double minPrice;
  final double maxPrice;
  final bool allInclusiveOnly;

  const SearchFilters({
    this.query = '',
    this.selectedCity = 'Semua',
    this.minPrice = 0.0,
    this.maxPrice = 10000000.0,
    this.allInclusiveOnly = false,
  });

  SearchFilters copyWith({
    String? query,
    String? selectedCity,
    double? minPrice,
    double? maxPrice,
    bool? allInclusiveOnly,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      selectedCity: selectedCity ?? this.selectedCity,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      allInclusiveOnly: allInclusiveOnly ?? this.allInclusiveOnly,
    );
  }
}

class SearchFiltersNotifier extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void update(SearchFilters Function(SearchFilters state) cb) {
    state = cb(state);
  }
}

final searchFiltersProvider = NotifierProvider<SearchFiltersNotifier, SearchFilters>(() {
  return SearchFiltersNotifier();
});

final searchProvider = FutureProvider<List<PropertyEntity>>((ref) async {
  final repository = ref.watch(propertyRepositoryProvider);
  final filters = ref.watch(searchFiltersProvider);

  final allProperties = await repository.getProperties();

  // 1. Filter locally
  var filtered = allProperties.where((prop) {
    // Query Filter (Title, Location/Regency, Full Address)
    if (filters.query.isNotEmpty) {
      final q = filters.query.toLowerCase();
      final titleMatch = prop.title.toLowerCase().contains(q);
      final locMatch = prop.location.toLowerCase().contains(q);
      final addrMatch = prop.address.toLowerCase().contains(q);
      if (!titleMatch && !locMatch && !addrMatch) {
        return false;
      }
    }

    // City Filter
    if (filters.selectedCity != 'Semua') {
      if (prop.location.toLowerCase() != filters.selectedCity.toLowerCase()) {
        return false;
      }
    }

    // Price Range Filter
    if (prop.maxPrice < filters.minPrice || prop.minPrice > filters.maxPrice) {
      return false;
    }

    // All-Inclusive Filter
    if (filters.allInclusiveOnly) {
      if (!prop.hasAllInclusive) {
        return false;
      }
    }

    return true;
  }).toList();

  // 2. Sort by Proximity to User Location:
  // User's location (Denpasar area) is at -8.6500, 115.2166
  const double userLat = -8.6500;
  const double userLng = 115.2166;

  filtered.sort((a, b) {
    final distA = _calculateProximity(userLat, userLng, a.latitude, a.longitude);
    final distB = _calculateProximity(userLat, userLng, b.latitude, b.longitude);
    return distA.compareTo(distB);
  });

  return filtered;
});

double _calculateProximity(double lat1, double lon1, double lat2, double lon2) {
  final p = 0.017453292519943295; // Math.PI / 180
  final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) * math.cos(lat2 * p) *
      (1 - math.cos((lon2 - lon1) * p)) / 2;
  return 12742 * math.asin(math.sqrt(a)) * 1000; // Returns distance in meters
}
