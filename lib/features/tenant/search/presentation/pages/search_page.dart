import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../booking/presentation/pages/contract_review_page.dart';
import '../widgets/property_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _isMapView = false;

  final List<Map<String, dynamic>> _mockProperties = [
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400',
      'title': 'Kos Eksklusif Mawar',
      'location': 'Jakarta Selatan',
      'price': 2500000.0,
      'rating': 4.8,
      'isAllInclusive': true,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400',
      'title': 'Kos Mahasiswa UI',
      'location': 'Depok',
      'price': 1500000.0,
      'rating': 4.5,
      'isAllInclusive': false,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400',
      'title': 'Premium Residence',
      'location': 'Jakarta Pusat',
      'price': 4500000.0,
      'rating': 4.9,
      'isAllInclusive': true,
    },
  ];

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
      body: _isMapView ? _buildMapView() : _buildListView(),
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

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _mockProperties.length,
      itemBuilder: (context, index) {
        final prop = _mockProperties[index];
        return PropertyCard(
          imageUrl: prop['imageUrl'],
          title: prop['title'],
          location: prop['location'],
          price: prop['price'],
          rating: prop['rating'],
          isAllInclusive: prop['isAllInclusive'],
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

  Widget _buildMapView() {
    return Stack(
      children: [
        // Mock Map Background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFE5E3DF), // Google Maps empty color
          child: CustomPaint(painter: _MockMapPainter()),
        ),

        // Mock Map Pins
        Positioned(top: 150, left: 100, child: _buildMapPin('2.5 Jt')),
        Positioned(
          top: 250,
          left: 200,
          child: _buildMapPin('4.5 Jt', isHighlighted: true),
        ),
        Positioned(top: 350, left: 80, child: _buildMapPin('1.5 Jt')),

        // Bottom Carousel Highlight
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                SizedBox(
                  width: 280,
                  child: PropertyCard(
                    imageUrl: 'imageUrl',
                    title: 'Premium Residence',
                    location: 'Jakarta Pusat',
                    price: 4500000.0,
                    rating: 4.9,
                    isAllInclusive: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContractReviewPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPin(String priceLabel, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        priceLabel,
        style: TextStyle(
          color: isHighlighted ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    // Draw some mock roads
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.5);

    final path2 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..lineTo(size.width * 0.6, size.height);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
