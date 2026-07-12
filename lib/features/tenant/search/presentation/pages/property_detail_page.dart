import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/pages/kyc_intro_page.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../landlord/dashboard/presentation/providers/landlord_provider.dart';
import '../../../booking/presentation/pages/contract_review_page.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';
import '../../data/models/room_model.dart';
import '../../domain/entities/property_entity.dart';
import '../../../../../core/widgets/custom_image.dart';

class PropertyDetailPage extends ConsumerStatefulWidget {
  final PropertyEntity property;

  const PropertyDetailPage({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends ConsumerState<PropertyDetailPage> {
  late Future<List<RoomModel>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    setState(() {
      _roomsFuture = ref
          .read(landlordRepositoryProvider)
          .getRoomsForProperty(widget.property.id);
    });
  }

  String _formatCurrency(double amount) {
    final valStr = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < valStr.length; i++) {
      if (i > 0 && (valStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(valStr[i]);
    }
    return buffer.toString();
  }

  void _onRentTapped(RoomModel room) {
    final authUser = ref.read(authProvider).user;
    if (authUser == null || !authUser.isVerified) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Verifikasi Diperlukan'),
          content: const Text(
              'Anda harus menyelesaikan verifikasi akun (KYC) terlebih dahulu sebelum dapat menyewa kos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const KycIntroPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Verifikasi Sekarang', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContractReviewPage(
            property: widget.property,
            room: room,
          ),
        ),
      ).then((_) => _loadRooms()); // Reload rooms when returning in case they rented it
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final String priceText;
    if (property.minPrice == property.maxPrice) {
      priceText = 'Rp ${(property.minPrice / 1000000).toStringAsFixed(1)} Jt';
    } else {
      priceText = 'Rp ${(property.minPrice / 1000000).toStringAsFixed(1)} - ${(property.maxPrice / 1000000).toStringAsFixed(1)} Jt';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header Image AppBar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: CustomImage(
                imageUrl: property.imageUrl,
                fit: BoxFit.cover,
                errorWidget: const Center(
                  child: Icon(Icons.home_work_rounded, size: 64, color: Colors.white70),
                ),
              ),
            ),
          ),

          // Detail Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              property.rating.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        property.location,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    property.address,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga Sewa',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Termasuk tipe bulanan',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                             Text(
                              priceText,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              ' / bln',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Deskripsi Properti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description.isNotEmpty
                        ? property.description
                        : 'Tidak ada deskripsi untuk properti ini.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Lokasi Properti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(property.latitude, property.longitude),
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.kosmo.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(property.latitude, property.longitude),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Room List Header
                  const Text(
                    'Daftar Pilihan Kamar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Room list loading
                  FutureBuilder<List<RoomModel>>(
                    future: _roomsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Gagal memuat kamar: ${snapshot.error}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }

                      final rooms = snapshot.data ?? [];
                      if (rooms.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Tidak ada kamar yang terdaftar di kos ini.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          final isOccupied = room.tenantId != null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Room photo
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    color: Colors.grey.shade100,
                                    child: CustomImage(
                                      imageUrl: room.imageUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: const Icon(
                                        Icons.bedroom_child_rounded,
                                        size: 36,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),

                                // Room details
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              room.roomNumber,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isOccupied
                                                    ? AppColors.error.withOpacity(0.1)
                                                    : Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                isOccupied ? 'Terisi' : 'Tersedia',
                                                style: TextStyle(
                                                  color: isOccupied ? AppColors.error : Colors.green,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          room.description.isNotEmpty
                                              ? room.description
                                              : 'Kamar nyaman dan bersih siap huni.',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Rp ${_formatCurrency(room.price)} / bln',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  if (room.isAllInclusive)
                                                    Text(
                                                      'Termasuk: ${room.allInclusiveBills ?? "Listrik, Air"}',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.blue,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              height: 32,
                                              child: ElevatedButton(
                                                onPressed: isOccupied ? null : () => _onRentTapped(room),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  disabledBackgroundColor: Colors.grey.shade300,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                ),
                                                child: Text(
                                                  isOccupied ? 'Sudah Terisi' : 'Sewa',
                                                  style: TextStyle(
                                                    color: isOccupied ? Colors.grey.shade600 : Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
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
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ulasan Properti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: ref.read(propertyRepositoryProvider).getReviewsForProperty(widget.property.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Text('Gagal memuat ulasan: ${snapshot.error}');
                      }
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Belum ada ulasan untuk kos ini.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          final String reviewerName = review['user_name'] ?? 'Pengguna';
                          final double rating = review['rating'] ?? 0.0;
                          final String comment = review['comment'] ?? '';
                          final String dateStr = review['date_str'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      child: const Icon(Icons.person_rounded, size: 12, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      reviewerName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        return Icon(
                                          starIdx < rating.floor()
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          color: AppColors.accent,
                                          size: 14,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  comment,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
