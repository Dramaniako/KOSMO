import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/mysql_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../landlord/dashboard/presentation/providers/landlord_provider.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';
import '../providers/transaction_provider.dart';

class ActiveRentalDetailPage extends ConsumerStatefulWidget {
  final ActiveRental activeRental;

  const ActiveRentalDetailPage({super.key, required this.activeRental});

  @override
  ConsumerState<ActiveRentalDetailPage> createState() =>
      _ActiveRentalDetailPageState();
}

class _ActiveRentalDetailPageState
    extends ConsumerState<ActiveRentalDetailPage> {
  bool _isLoading = false;

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

  void _showStopRentingConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Berhenti Menyewa?'),
        content: Text(
          'Apakah Anda yakin ingin berhenti menyewa ${widget.activeRental.propertyTitle} (${widget.activeRental.roomNumber})?\n\nKontrak sewa Anda akan dihentikan dan Anda harus mengosongkan kamar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordVerification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Berhenti',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPasswordVerification() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konfirmasi Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan password akun Anda untuk mengkonfirmasi penghentian sewa kos ini.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: errorText,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final password = passwordController.text.trim();
                      if (password.isEmpty) {
                        setDialogState(() {
                          errorText = 'Password tidak boleh kosong';
                        });
                        return;
                      }

                      setDialogState(() {
                        _isLoading = true;
                      });

                      try {
                        final authUser = ref.read(authProvider).user;
                        if (authUser == null)
                          throw Exception('User session not found');

                        final isValid = await ref
                            .read(landlordRepositoryProvider)
                            .verifyPassword(
                              authUser.id!,
                              password,
                            );

                        if (!isValid) {
                          setDialogState(() {
                            _isLoading = false;
                            errorText = 'Password salah';
                          });
                          return;
                        }

                        // Process checkout/stop renting
                        final mysqlService = ref.read(mysqlServiceProvider);
                        await mysqlService.run((conn) async {
                          // 1. Free the room
                          await conn.execute(
                            "UPDATE rooms SET tenant_id = NULL WHERE id = :id",
                            {"id": widget.activeRental.id},
                          );

                          // 2. Recalculate occupied_rooms
                          await conn.execute(
                            "UPDATE properties SET occupied_rooms = "
                            "(SELECT COUNT(*) FROM rooms WHERE property_id = :propId AND tenant_id IS NOT NULL) "
                            "WHERE id = :propId",
                            {"propId": widget.activeRental.propertyId},
                          );
                        });

                        // 3. Refresh providers
                        ref.invalidate(transactionProvider);
                        ref.invalidate(activeRentalProvider);
                        ref.invalidate(searchProvider);
                        ref.invalidate(landlordProvider);

                        if (!mounted) return;
                        Navigator.pop(ctx); // pop password dialog
                        Navigator.pop(context); // pop active rental page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Anda telah berhasil berhenti menyewa kos.'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() {
                          _isLoading = false;
                          errorText = 'Terjadi kesalahan: $e';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Konfirmasi',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rental = widget.activeRental;
    final priceJt = (rental.price / 1000000).toStringAsFixed(1);
    final bills =
        rental.allInclusiveBills != null && rental.allInclusiveBills!.isNotEmpty
            ? rental.allInclusiveBills!.split(',')
            : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Sewa Aktif',
            style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image Card
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 180,
                color: Colors.grey.shade200,
                child: rental.imageUrl.isNotEmpty
                    ? Image.network(
                        rental.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.broken_image_rounded,
                              size: 64, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.home_work_rounded,
                        size: 64, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),

            // Header info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    rental.propertyTitle,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Sewa Aktif',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${rental.roomNumber} • Rp $priceJt Jt / bulan',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 12),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rental.address,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Property description
            const Text(
              'Deskripsi Properti',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              rental.description.isNotEmpty
                  ? rental.description
                  : 'Kos dengan fasilitas kamar mandi dalam, kasur, lemari, meja belajar, AC, dan area jemur.',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Included bills
            if (bills.isNotEmpty) ...[
              const Text(
                'Tagihan Bundling All-Inclusive',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bills.map((bill) {
                  return Chip(
                    avatar: const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 14),
                    label: Text(bill,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textPrimary)),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade200),
                  );
                }).toList(),
              ),
              const Divider(height: 32),
            ],

            // Landlord info
            const Text(
              'Informasi Pemilik Kos',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                        color: AppColors.background, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rental.landlordName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rental.landlordEmail,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rental.landlordEmail,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Stop renting button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _showStopRentingConfirmation,
                icon:
                    const Icon(Icons.exit_to_app_rounded, color: Colors.white),
                label: const Text(
                  'Berhenti Menyewa Kos',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
