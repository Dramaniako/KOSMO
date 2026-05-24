import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../booking/presentation/pages/contract_review_page.dart';
import '../../domain/entities/property_entity.dart';
import '../providers/search_provider.dart';
import '../widgets/property_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> with TickerProviderStateMixin {
  bool _isMapView = false;
  String _activeTheme = 'light'; // 'light', 'dark', 'satellite'
  double _radarRadiusMeters = 1000.0; // 500.0, 1000.0, 2000.0
  int _activePropertyIndex = 0;

  // Map Animation and Positioning Controllers
  late TransformationController _transformationController;
  late AnimationController _mapAnimationController;
  Animation<Matrix4>? _mapMatrixAnimation;

  // Radar pulse animation
  late AnimationController _radarPulseController;

  // Carousel controller
  late PageController _pageController;
  bool _isSyncingFromCarousel = false;

  // Search input & autocomplete state
  final TextEditingController _searchController = TextEditingController();
  bool _showAutocomplete = false;
  final FocusNode _searchFocusNode = FocusNode();

  // Map settings
  final double _mapVirtualWidth = 1500.0;
  final double _mapVirtualHeight = 1500.0;

  // Bounding box for Jakarta / Depok mock projections
  // Latitude: -6.42 (south) to -6.18 (north)
  // Longitude: 106.75 (west) to 106.88 (east)
  final double _minLat = -6.42;
  final double _maxLat = -6.18;
  final double _minLng = 106.75;
  final double _maxLng = 106.88;

  // User location (Setiabudi area)
  final double _userLat = -6.2150;
  final double _userLng = 106.8400;
  final double _userCompassHeading = 45.0; // Heading in degrees

  // List of transit hubs for overlays
  final List<Map<String, dynamic>> _transitHubs = [
    {
      'name': 'MRT Setiabudi Astra',
      'lat': -6.2100,
      'lng': 106.8420,
    },
    {
      'name': 'Stasiun Blok M BCA',
      'lat': -6.2420,
      'lng': 106.7970,
    },
    {
      'name': 'Stasiun UI Depok',
      'lat': -6.3650,
      'lng': 106.8310,
    }
  ];

  // Autocomplete suggestions
  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'Setiabudi, Jakarta Pusat',
      'lat': -6.2088,
      'lng': 106.8456,
    },
    {
      'name': 'Blok M, Jakarta Selatan',
      'lat': -6.2442,
      'lng': 106.7982,
    },
    {
      'name': 'Universitas Indonesia, Depok',
      'lat': -6.3680,
      'lng': 106.8320,
    },
  ];

  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _pageController = PageController(viewportFraction: 0.85);

    // Centering animation setup
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Pulse radar animation setup
    _radarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Center on user location initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnCoordinates(_userLat, _userLng, initialScale: 1.2);
    });

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
    _transformationController.dispose();
    _mapAnimationController.dispose();
    _radarPulseController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Haversine formula to compute distance in meters
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  // Translate lat/lng to virtual grid canvas offset
  Offset _latLngToOffset(double lat, double lng) {
    double x = ((lng - _minLng) / (_maxLng - _minLng)) * _mapVirtualWidth;
    double y = (1.0 - ((lat - _minLat) / (_maxLat - _minLat))) * _mapVirtualHeight;
    return Offset(x, y);
  }

  // Center maps dynamically
  void _centerOnCoordinates(double lat, double lng, {double initialScale = 1.6}) {
    final Size screenSize = MediaQuery.of(context).size;
    final Offset targetOffset = _latLngToOffset(lat, lng);

    final double startX = screenSize.width / 2 - targetOffset.dx * initialScale;
    final double startY = (screenSize.height - 280) / 2 - targetOffset.dy * initialScale;

    _transformationController.value = Matrix4.identity()
      ..translate(startX, startY)
      ..scale(initialScale);
  }

  // Center maps smoothly with animation
  void _animateToCoordinates(double lat, double lng, {double targetScale = 1.6}) {
    final Size screenSize = MediaQuery.of(context).size;
    final Offset targetOffset = _latLngToOffset(lat, lng);

    final double targetX = screenSize.width / 2 - targetOffset.dx * targetScale;
    final double targetY = (screenSize.height - 280) / 2 - targetOffset.dy * targetScale;

    final Matrix4 endMatrix = Matrix4.identity()
      ..translate(targetX, targetY)
      ..scale(targetScale);

    _mapAnimationController.stop();
    _mapAnimationController.reset();

    _mapMatrixAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _mapAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    _mapMatrixAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _mapMatrixAnimation!.value;
      }
    });

    _mapAnimationController.forward();
  }

  void _onSearchTextChanged(String text) {
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
    _searchFocusNode.unfocus();
    setState(() {
      _showAutocomplete = false;
    });

    // Animate map to location coordinates
    _animateToCoordinates(
      location['lat'] as double,
      location['lng'] as double,
      targetScale: 1.8,
    );
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
            data: (properties) => _isMapView ? _buildMapView(properties) : _buildListView(properties),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(searchProvider),
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
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
            itemBuilder: (context, index) {
              final loc = _filteredLocations[index];
              return ListTile(
                leading: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                title: Text(
                  loc['name'] as String,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
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
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final prop = properties[index];
        return PropertyCard(
          imageUrl: prop.imageUrl,
          title: prop.title,
          location: prop.location,
          price: prop.price,
          rating: prop.rating,
          isAllInclusive: prop.isAllInclusive,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContractReviewPage(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapView(List<PropertyEntity> properties) {
    return Stack(
      children: [
        // Interactive Maps Zoom & Pan Canvas
        GestureDetector(
          onDoubleTapDown: (details) {
            // Smooth zoom-in on double tap
            final currentScale = _transformationController.value.getMaxScaleOnAxis();
            final localPos = details.localPosition;
            final targetScale = currentScale < 2.5 ? 2.5 : 1.2;
            _animateToCoordinates(
              _minLat + ((_mapVirtualHeight - localPos.dy) / _mapVirtualHeight) * (_maxLat - _minLat),
              _minLng + (localPos.dx / _mapVirtualWidth) * (_maxLng - _minLng),
              targetScale: targetScale,
            );
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(400),
            minScale: 0.6,
            maxScale: 3.5,
            child: SizedBox(
              width: _mapVirtualWidth,
              height: _mapVirtualHeight,
              child: Stack(
                children: [
                  // Vector Styled Maps Paint Layout
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapBackgroundPainter(
                        theme: _activeTheme,
                        userOffset: _latLngToOffset(_userLat, _userLng),
                        radarRadiusPixels: _radarRadiusMeters * 0.15, // Scale meter to screen pixel
                      ),
                    ),
                  ),

                  // Radar scan circle overlay centered on user location
                  Positioned(
                    left: _latLngToOffset(_userLat, _userLng).dx - (_radarRadiusMeters * 0.15),
                    top: _latLngToOffset(_userLat, _userLng).dy - (_radarRadiusMeters * 0.15),
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _radarPulseController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(_radarRadiusMeters * 0.3, _radarRadiusMeters * 0.3),
                            painter: _RadarOverlayPainter(
                              _radarPulseController.value,
                              _activeTheme,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Transit Station Badges
                  ..._transitHubs.map((hub) {
                    final pos = _latLngToOffset(hub['lat'] as double, hub['lng'] as double);
                    return Positioned(
                      left: pos.dx - 12,
                      top: pos.dy - 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _activeTheme == 'dark' ? Colors.grey.shade900 : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          border: Border.all(color: Colors.purple.shade400, width: 2),
                        ),
                        child: Icon(Icons.directions_subway_rounded, color: Colors.purple.shade400, size: 14),
                      ),
                    );
                  }),

                  // User Location Pulse
                  Positioned(
                    left: _latLngToOffset(_userLat, _userLng).dx - 16,
                    top: _latLngToOffset(_userLat, _userLng).dy - 16,
                    child: AnimatedBuilder(
                      animation: _radarPulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse circle
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
                            // Compass heading indicator
                            Transform.rotate(
                              angle: _userCompassHeading * pi / 180.0,
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: Colors.blueAccent,
                                size: 24,
                              ),
                            ),
                            // Core point
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 2)],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Property price pins
                  ...properties.asMap().entries.map((entry) {
                    final index = entry.key;
                    final prop = entry.value;
                    final pos = _latLngToOffset(prop.latitude, prop.longitude);
                    final isHighlighted = index == _activePropertyIndex;

                    // Haversine distance
                    final distance = _calculateDistance(_userLat, _userLng, prop.latitude, prop.longitude);
                    final isInsideRadar = distance <= _radarRadiusMeters;

                    return Positioned(
                      left: pos.dx - 32,
                      top: pos.dy - 35,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activePropertyIndex = index;
                            _isSyncingFromCarousel = true;
                          });
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ).then((_) => _isSyncingFromCarousel = false);
                          _animateToCoordinates(prop.latitude, prop.longitude);
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isInsideRadar ? 1.0 : 0.45,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pin layout
                              Icon(
                                Icons.location_on_rounded,
                                size: isHighlighted ? 68 : 52,
                                color: isHighlighted
                                    ? AppColors.primary
                                    : (isInsideRadar ? Colors.teal.shade500 : Colors.grey.shade600),
                              ),
                              Positioned(
                                top: isHighlighted ? 14 : 11,
                                child: Text(
                                  'Rp ${(prop.price / 1000000).toStringAsFixed(1)} Jt',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isHighlighted ? 10 : 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Warning badge if outside radar
                              if (!isInsideRadar)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                    child: const Icon(Icons.warning_rounded, color: Colors.white, size: 10),
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
            ),
          ),
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
                onTap: () => _animateToCoordinates(_userLat, _userLng, targetScale: 1.5),
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
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar_rounded, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Radar: ${(_radarRadiusMeters).toInt()}m',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: 20,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
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
                _animateToCoordinates(prop.latitude, prop.longitude);
              },
              itemBuilder: (context, index) {
                final prop = properties[index];
                final isHighlighted = index == _activePropertyIndex;
                final dist = _calculateDistance(_userLat, _userLng, prop.latitude, prop.longitude);
                final isInsideRadar = dist <= _radarRadiusMeters;

                return _buildCompactPropertyCard(prop, isHighlighted, isInsideRadar, dist);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlBtn({required IconData icon, required String tooltip, required VoidCallback onTap}) {
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

  Widget _buildCompactPropertyCard(PropertyEntity prop, bool isHighlighted, bool isInsideRadar, double dist) {
    // Estimations
    final walkingMin = (dist / 80).round(); // ~80 meters per minute walking speed

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
                  child: prop.imageUrl.isNotEmpty
                      ? Image.network(prop.imageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.home_work_rounded, color: Colors.grey),
                ),
                // Rating Badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          prop.rating.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
                            const Icon(Icons.location_on_rounded, size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                prop.location,
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
                          isInsideRadar ? Icons.check_circle_rounded : Icons.info_outline_rounded,
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
                            color: isInsideRadar ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp ${(prop.price / 1000000).toStringAsFixed(1)} Jt / bln',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ContractReviewPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Sewa',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

// Vector Styled Map Background Painter
class _MapBackgroundPainter extends CustomPainter {
  final String theme;
  final Offset userOffset;
  final double radarRadiusPixels;

  _MapBackgroundPainter({
    required this.theme,
    required this.userOffset,
    required this.radarRadiusPixels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Establish palette colors
    late Color bgColor;
    late Color roadColor;
    late Color highwayColor;
    late Color riverColor;
    late Color parkColor;
    late Color gridColor;
    late Color textStyleColor;
    late Color buildingColor;

    if (theme == 'dark') {
      bgColor = const Color(0xFF161618);
      roadColor = const Color(0xFF232326);
      highwayColor = const Color(0xFF2E2E33);
      riverColor = const Color(0xFF1B2E4E);
      parkColor = const Color(0xFF132A1D);
      gridColor = const Color(0xFF28282D);
      textStyleColor = Colors.grey.shade500;
      buildingColor = const Color(0xFF1F1F23);
    } else if (theme == 'satellite') {
      bgColor = const Color(0xFF0C101A);
      roadColor = const Color(0xFF202636);
      highwayColor = const Color(0xFF2E374D);
      riverColor = const Color(0xFF0F1E38);
      parkColor = const Color(0xFF0A1F13);
      gridColor = const Color(0xFF1C2436);
      textStyleColor = Colors.tealAccent.shade400;
      buildingColor = const Color(0xFF141A29);
    } else {
      // Default: Light Theme
      bgColor = const Color(0xFFF6F5F2);
      roadColor = Colors.white;
      highwayColor = const Color(0xFFFCF5E3);
      riverColor = const Color(0xFFC4DBFC);
      parkColor = const Color(0xFFDCF8DF);
      gridColor = const Color(0xFFECEAE4);
      textStyleColor = Colors.grey.shade600;
      buildingColor = const Color(0xFFEBEBEB);
    }

    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw Coordinates Grid (Satellite Theme)
    if (theme == 'satellite') {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1.0;

      for (double i = 0; i < size.width; i += 100) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
        canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
      }

      // Contour elevation rings
      final contourPaint = Paint()
        ..color = Colors.tealAccent.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.3), 350, contourPaint);
      canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.3), 600, contourPaint);
    }

    // 3. Draw Waterways / Rivers (flowing curve)
    final riverPaint = Paint()
      ..color = riverColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(-50, size.height * 0.1)
      ..cubicTo(
        size.width * 0.3, size.height * 0.15,
        size.width * 0.4, size.height * 0.8,
        size.width + 50, size.height * 0.85,
      );
    canvas.drawPath(riverPath, riverPaint);

    // 4. Draw Green Parks (Taman Kota)
    final parkPaint = Paint()..color = parkColor;
    // Park 1 (Top Left)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(80, 120, 240, 160),
        const Radius.circular(32),
      ),
      parkPaint,
    );
    // Park 2 (Center Right)
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.4), 130, parkPaint);
    // Park 3 (Bottom Center UI Forest)
    canvas.drawOval(Rect.fromLTWH(800, 1050, 300, 220), parkPaint);

    // 5. Draw City Block Building Outlines
    final buildPaint = Paint()..color = buildingColor;
    final List<Rect> mockBuildings = [
      Rect.fromLTWH(420, 100, 80, 70),
      Rect.fromLTWH(520, 80, 60, 90),
      Rect.fromLTWH(440, 200, 90, 80),
      Rect.fromLTWH(620, 150, 120, 110),
      Rect.fromLTWH(180, 380, 70, 70),
      Rect.fromLTWH(270, 390, 80, 60),
      Rect.fromLTWH(750, 720, 90, 100),
      Rect.fromLTWH(870, 700, 70, 90),
    ];
    for (var r in mockBuildings) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), buildPaint);
    }

    // 6. Draw Primary Highways & Normal Roads
    final roadPaint = Paint()
      ..color = roadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final hwPaint = Paint()
      ..color = highwayColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    // Outer borders for roads to give depth
    final roadBorderPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;

    final hwBorderPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;

    // Road paths
    final Path highway1 = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.2, size.height);

    final Path highway2 = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.5);

    // Diagonal arterial roads
    final Path road1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.3);

    final Path road2 = Path()
      ..moveTo(size.width * 0.6, 0)
      ..lineTo(size.width * 0.6, size.height);

    final Path road3 = Path()
      ..moveTo(200, 800)
      ..lineTo(1300, 1300);

    // Draw borders first
    canvas.drawPath(highway1, hwBorderPaint);
    canvas.drawPath(highway2, hwBorderPaint);
    canvas.drawPath(road1, roadBorderPaint);
    canvas.drawPath(road2, roadBorderPaint);
    canvas.drawPath(road3, roadBorderPaint);

    // Draw solid roads on top
    canvas.drawPath(highway1, hwPaint);
    canvas.drawPath(highway2, hwPaint);
    canvas.drawPath(road1, roadPaint);
    canvas.drawPath(road2, roadPaint);
    canvas.drawPath(road3, roadPaint);

    // 7. Text tags for major districts
    _paintText(canvas, 'SUDIRMAN CENTRAL', Offset(size.width * 0.22, size.height * 0.22), textStyleColor, fontSize: 13, isBold: true);
    _paintText(canvas, 'TAMAN SETIABUDI', Offset(100, 180), textStyleColor.withValues(alpha: 0.8), fontSize: 10, isBold: false);
    _paintText(canvas, 'BLOK M SQUARE', Offset(460, 420), textStyleColor, fontSize: 11, isBold: true);
    _paintText(canvas, 'HUTAN KOTA UI', Offset(860, 1140), textStyleColor.withValues(alpha: 0.8), fontSize: 10, isBold: false);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    required double fontSize,
    required bool isBold,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MapBackgroundPainter oldDelegate) {
    return oldDelegate.theme != theme ||
        oldDelegate.userOffset != userOffset ||
        oldDelegate.radarRadiusPixels != radarRadiusPixels;
  }
}

// Radar scanning overlay painter
class _RadarOverlayPainter extends CustomPainter {
  final double pulseProgress;
  final String theme;

  _RadarOverlayPainter(this.pulseProgress, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Glowing active radius
    final radarColor = theme == 'dark' ? Colors.blue.withValues(alpha: 0.08) : Colors.blue.withValues(alpha: 0.05);
    final fillPaint = Paint()
      ..color = radarColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, fillPaint);

    // Border line
    final borderPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, maxRadius, borderPaint);

    // Moving scan sweep line
    final sweepAngle = pulseProgress * 2 * pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.blueAccent.withValues(alpha: 0.25),
          Colors.blueAccent.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // Extra pulsing inner rings
    final pulsePaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.3 * (1.0 - pulseProgress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, maxRadius * pulseProgress, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarOverlayPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress || oldDelegate.theme != theme;
  }
}
