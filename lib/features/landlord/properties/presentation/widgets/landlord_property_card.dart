import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_image.dart';

class LandlordPropertyCard extends StatelessWidget {
  final String title;
  final String address;
  final int totalRooms;
  final int occupiedRooms;
  final String imageUrl;
  final VoidCallback? onDelete;
  final VoidCallback? onManageProperty;

  const LandlordPropertyCard({
    super.key,
    required this.title,
    required this.address,
    required this.totalRooms,
    required this.occupiedRooms,
    required this.imageUrl,
    this.onDelete,
    this.onManageProperty,
  });

  @override
  Widget build(BuildContext context) {
    final double occupancyRate =
        totalRooms > 0 ? occupiedRooms / totalRooms : 0;
    final bool isFull = totalRooms > 0 && occupiedRooms == totalRooms;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: AppColors.border,
                  child: CustomImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: const Icon(
                      Icons.apartment_rounded,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Delete Button (top-left)
                if (onDelete != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: const Color.fromARGB(137, 255, 255, 255),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Color.fromARGB(255, 255, 0, 0),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Status Badge (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFull ? AppColors.secondary : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFull ? 'Penuh' : 'Tersedia',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Occupancy Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Keterisian',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary),
                    ),
                    Text(
                      '$occupiedRooms/$totalRooms Kamar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFull ? AppColors.secondary : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: occupancyRate,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFull ? AppColors.secondary : AppColors.primary,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onManageProperty,
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Kelola Property'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
