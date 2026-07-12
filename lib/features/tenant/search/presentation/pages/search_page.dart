import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import 'property_detail_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/pages/kyc_intro_page.dart';
import '../../domain/entities/property_entity.dart';
import '../providers/search_provider.dart';
import '../widgets/property_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../../../../core/widgets/custom_image.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with TickerProviderStateMixin {
  bool _isMapView = false;
  String _activeTheme = 'light'; // 'light', 'dark', 'satellite'
  double _radarRadiusMeters = 1000.0; // 500.0, 1000.0, 2000.0
  int _activePropertyIndex = 0;

  // Map Animation and Positioning Controllers
  late MapController _mapController;

  // Radar pulse animation
  late AnimationController _radarPulseController;

  // Carousel controller
  late PageController _pageController;
  bool _isSyncingFromCarousel = false;

  // Search input & autocomplete state
  final TextEditingController _searchController = TextEditingController();
  bool _showAutocomplete = false;
  final FocusNode _searchFocusNode = FocusNode();

  // User location (Denpasar area)
  double _userLat = -8.6500;
  double _userLng = 115.2166;
  final double _userCompassHeading = 45.0; // Heading in degrees
  late ScrollController _listScrollController;
  int _visibleCount = 10;

  // Autocomplete suggestions
  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'Denpasar, Bali',
      'lat': -8.6500,
      'lng': 115.2166,
    },
    {
      'name': 'Kuta, Badung, Bali',
      'lat': -8.7225,
      'lng': 115.1825,
    },
    {
      'name': 'Jimbaran, Badung, Bali',
      'lat': -8.7980,
      'lng': 115.1700,
    },
    {
      'name': 'Ubud, Gianyar, Bali',
      'lat': -8.5069,
      'lng': 115.2625,
    },
  ];

  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pageController = PageController(viewportFraction: 0.85);
    _listScrollController = ScrollController();
    _listScrollController.addListener(() {
      if (_listScrollController.position.pixels >= _listScrollController.position.maxScrollExtent - 100) {
        setState(() {
          _visibleCount += 10;
        });
      }
    });

    // Pulse radar animation setup
    _radarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          _showAutocomplete = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _radarPulseController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  // Haversine formula to compute distance in meters
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final phi1 = lat1 * pi / 180.0;
    final phi2 = lat2 * pi / 180.0;
    final deltaPhi = (lat2 - lat1) * pi / 180.0;
    final deltaLambda = (lon2 - lon1) * pi / 180.0;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return r * c;
  }

  void _onSearchTextChanged(String text) {
    ref
        .read(searchFiltersProvider.notifier)
        .update((state) => state.copyWith(query: text));
    if (text.isEmpty) {
      setState(() {
        _filteredLocations = [];
        _showAutocomplete = false;
      });
      return;
    }

    final query = text.toLowerCase();
    setState(() {
      _filteredLocations = _locations.where((loc) {
        return (loc['name'] as String).toLowerCase().contains(query);
      }).toList();
      _showAutocomplete = _filteredLocations.isNotEmpty;
    });
  }

  void _onLocationSelected(Map<String, dynamic> location) {
    _searchController.text = location['name'] as String;
    ref
        .read(searchFiltersProvider.notifier)
        .update((state) => state.copyWith(query: location['name'] as String));
    _searchFocusNode.unfocus();
    setState(() {
      _showAutocomplete = false;
      _userLat = location['lat'] as double;
      _userLng = location['lng'] as double;
      _visibleCount = 10;
    });

    if (_isMapView) {
      _mapController.move(
        latlong.LatLng(location['lat'] as double, location['lng'] as double),
        14.0,
      );
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: _buildSearchBar(),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list_rounded : Icons.map_rounded),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          searchState.when(
            data: (properties) {
              final filteredProps = properties.where((prop) {
                final dist = _calculateDistance(_userLat, _userLng, prop.latitude, prop.longitude);
                return dist <= _radarRadiusMeters;
              }).toList();

              return _isMapView
                  ? _buildMapView(filteredProps)
                  : _buildListView(properties);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(propertiesListProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showAutocomplete) _buildAutocompleteDropdown(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchTextChanged,
              decoration: const InputDecoration(
                hintText: 'Cari lokasi atau nama kos...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          GestureDetector(
            onTap: _showFilterModal,
            child: const Padding(
              padding: EdgeInsets.only(
                right: 16.0,
                left: 8.0,
                top: 4,
                bottom: 4,
              ),
              child: Icon(
                Icons.tune_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteDropdown() {
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 180),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.black12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _filteredLocations.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Colors.black12),
            itemBuilder: (context, index) {
              final loc = _filteredLocations[index];
              return ListTile(
                leading: const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 20),
                title: Text(
                  loc['name'] as String,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                ),
                onTap: () => _onLocationSelected(loc),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<PropertyEntity> properties) {
    if (properties.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Tidak ada kos dalam radius radar pencarian.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    final displayCount = min(_visibleCount, properties.length);
    return ListView.builder(
      controller: _listScrollController,
      padding: const EdgeInsets.all(24),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        final prop = properties[index];
        return PropertyCard(
          imageUrl: prop.imageUrl,
          title: prop.title,
          location: prop.location,
          minPrice: prop.minPrice,
          maxPrice: prop.maxPrice,
          rating: prop.rating,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailPage(property: prop),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapView(List<PropertyEntity> properties) {
    String tileUrl;
    if (_activeTheme == 'dark') {
      tileUrl = 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
    } else if (_activeTheme == 'satellite') {
      tileUrl =
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    } else {
      tileUrl = 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    }

    return Stack(
      children: [
        // Real Interactive Map (OSM / CartoDB / Esri Satellite)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: latlong.LatLng(_userLat, _userLng),
            initialZoom: 13.0,
            maxZoom: 18.0,
            minZoom: 9.0,
            onTap: (tapPosition, point) {
              setState(() {
                _userLat = point.latitude;
                _userLng = point.longitude;
                _visibleCount = 10;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: 'com.kosmo.app',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: latlong.LatLng(_userLat, _userLng),
                  radius: _radarRadiusMeters,
                  useRadiusInMeter: true,
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderColor: Colors.blueAccent.withValues(alpha: 0.3),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                // User location
                Marker(
                  point: latlong.LatLng(_userLat, _userLng),
                  width: 44,
                  height: 44,
                  child: AnimatedBuilder(
                    animation: _radarPulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 1.0 - _radarPulseController.value,
                            child: Container(
                              width: 32 * _radarPulseController.value,
                              height: 32 * _radarPulseController.value,
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Transform.rotate(
                            angle: _userCompassHeading * pi / 180.0,
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Colors.blueAccent,
                              size: 24,
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black54, blurRadius: 2)
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Properties
                ...properties.asMap().entries.map((entry) {
                  final index = entry.key;
                  final prop = entry.value;
                  final isHighlighted = index == _activePropertyIndex;
                  final dist = _calculateDistance(
                      _userLat, _userLng, prop.latitude, prop.longitude);
                  final isInsideRadar = dist <= _radarRadiusMeters;

                  return Marker(
                    point: latlong.LatLng(prop.latitude, prop.longitude),
                    width: isHighlighted ? 80 : 64,
                    height: isHighlighted ? 80 : 64,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _activePropertyIndex = index;
                          _isSyncingFromCarousel = true;
                        });
                        _pageController
                            .animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                            .then((_) => _isSyncingFromCarousel = false);
                        _mapController.move(
                            latlong.LatLng(prop.latitude, prop.longitude),
                            _mapController.camera.zoom);
                      },
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isInsideRadar ? 1.0 : 0.45,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: isHighlighted ? 68 : 52,
                              color: isHighlighted
                                  ? AppColors.primary
                                  : (isInsideRadar
                                      ? Colors.teal.shade500
                                      : Colors.grey.shade600),
                            ),
                            Positioned(
                              top: isHighlighted ? 14 : 11,
                              child: Text(
                                'Rp ${(prop.minPrice / 1000000).toStringAsFixed(1)} Jt',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isHighlighted ? 10 : 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isInsideRadar)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.warning_rounded,
                                      color: Colors.white, size: 10),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // Map Control Panels (Themes, Radius Filters, Sync display)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Theme Toggle
              _buildMapControlBtn(
                icon: Icons.layers_rounded,
                tooltip: 'Ganti Gaya Peta',
                onTap: _toggleMapTheme,
              ),
              const SizedBox(height: 12),
              // Center on User
              _buildMapControlBtn(
                icon: Icons.my_location_rounded,
                tooltip: 'Pusatkan Lokasi Saya',
                onTap: () {
                  setState(() {
                    _userLat = -8.6500;
                    _userLng = 115.2166;
                    _visibleCount = 10;
                  });
                  _mapController.move(
                      latlong.LatLng(_userLat, _userLng), 14.0);
                },
              ),
            ],
          ),
        ),

        // Radar Distance Slider (Radar Control Center)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8)
              ],
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar_rounded,
                    color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Radar: ${(_radarRadiusMeters).toInt()}m',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: 20,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12.0),
                      trackHeight: 3,
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: Colors.blueAccent,
                    ),
                    child: Slider(
                      value: _radarRadiusMeters,
                      min: 500,
                      max: 2000,
                      divisions: 3,
                      onChanged: (val) {
                        setState(() {
                          _radarRadiusMeters = val;
                          _visibleCount = 10;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom PageView Horizontal Property Carousel
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 124,
            child: PageView.builder(
              controller: _pageController,
              itemCount: properties.length,
              onPageChanged: (index) {
                if (_isSyncingFromCarousel) return;
                setState(() {
                  _activePropertyIndex = index;
                });
                final prop = properties[index];
                _mapController.move(
                    latlong.LatLng(prop.latitude, prop.longitude),
                    _mapController.camera.zoom);
              },
              itemBuilder: (context, index) {
                final prop = properties[index];
                final isHighlighted = index == _activePropertyIndex;
                final dist = _calculateDistance(
                    _userLat, _userLng, prop.latitude, prop.longitude);
                final isInsideRadar = dist <= _radarRadiusMeters;

                return _buildCompactPropertyCard(
                    prop, isHighlighted, isInsideRadar, dist);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlBtn(
      {required IconData icon,
      required String tooltip,
      required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            border: Border.all(color: Colors.black12),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }

  void _toggleMapTheme() {
    setState(() {
      if (_activeTheme == 'light') {
        _activeTheme = 'dark';
      } else if (_activeTheme == 'dark') {
        _activeTheme = 'satellite';
      } else {
        _activeTheme = 'light';
      }
    });
  }

  Widget _buildCompactPropertyCard(PropertyEntity prop, bool isHighlighted,
      bool isInsideRadar, double dist) {
    // Estimations
    final walkingMin =
        (dist / 80).round(); // ~80 meters per minute walking speed

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isInsideRadar ? 0.95 : 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? AppColors.primary : Colors.black12,
          width: isHighlighted ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isHighlighted ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Property Image (Left)
            Stack(
              children: [
                Container(
                  width: 95,
                  height: double.infinity,
                  color: Colors.grey.shade200,
                  child: CustomImage(
                    imageUrl: prop.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Rating Badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          prop.rating.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Property Details (Right)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prop.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                prop.location,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Radar proximity calculations
                    Row(
                      children: [
                        Icon(
                          isInsideRadar
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 11,
                          color: isInsideRadar ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isInsideRadar
                              ? '${dist.toInt()}m ($walkingMin mnt jln kaki)'
                              : 'Di luar radar (+${(dist - _radarRadiusMeters).toInt()}m)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isInsideRadar
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prop.minPrice == prop.maxPrice
                              ? 'Rp ${(prop.minPrice / 1000000).toStringAsFixed(1)} Jt / bln'
                              : 'Rp ${(prop.minPrice / 1000000).toStringAsFixed(1)} - ${(prop.maxPrice / 1000000).toStringAsFixed(1)} Jt / bln',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertyDetailPage(property: prop),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Detail',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
