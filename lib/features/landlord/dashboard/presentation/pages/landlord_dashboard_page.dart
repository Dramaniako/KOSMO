import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../properties/presentation/widgets/landlord_property_card.dart';
import '../../../properties/presentation/pages/add_property_page.dart';
import '../../../properties/presentation/pages/manage_property_page.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/pages/kyc_intro_page.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';
import '../providers/landlord_provider.dart';
import 'landlord_withdraw_page.dart';
import '../../../properties/presentation/pages/landlord_profile_setup_page.dart';
import '../../data/models/landlord_stats_model.dart';
import '../../data/models/landlord_property_model.dart';

class LandlordDashboardPage extends ConsumerStatefulWidget {
  const LandlordDashboardPage({super.key});

  @override
  ConsumerState<LandlordDashboardPage> createState() => _LandlordDashboardPageState();
}

class _LandlordDashboardPageState extends ConsumerState<LandlordDashboardPage> {

  String _formatCurrency(double amount) {
    final valStr = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < valStr.length; i++) {
      if (i > 0 && (valStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(valStr[i]);
    }
    return 'Rp ${buffer.toString()}';
  }

  /// Layer 1: "Are you sure?" confirmation dialog
  void _showDeleteConfirmation(LandlordPropertyModel property) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Properti?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                children: [
                  const TextSpan(text: 'Anda akan menghapus properti '),
                  TextSpan(
                    text: '"${property.title}"',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const TextSpan(text: ' beserta seluruh data kamar yang terkait. '),
                  const TextSpan(
                    text: 'Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${property.totalRooms} kamar akan ikut dihapus',
                      style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showPasswordConfirmation(property);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Layer 2: Password verification dialog
  void _showPasswordConfirmation(LandlordPropertyModel property) {
    final passwordController = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 24),
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
                'Masukkan password akun Anda untuk mengkonfirmasi penghapusan properti ini.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                onSubmitted: (_) {
                  if (!isLoading) {
                    _performDelete(ctx, property, passwordController.text, setDialogState, (loading) {
                      isLoading = loading;
                    }, (error) {
                      errorText = error;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      _performDelete(ctx, property, passwordController.text, setDialogState, (loading) {
                        isLoading = loading;
                      }, (error) {
                        errorText = error;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Hapus Permanen', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performDelete(
    BuildContext dialogContext,
    LandlordPropertyModel property,
    String password,
    void Function(void Function()) setDialogState,
    void Function(bool) setLoading,
    void Function(String?) setError,
  ) async {
    if (password.isEmpty) {
      setDialogState(() {
        setError('Password tidak boleh kosong');
      });
      return;
    }

    setDialogState(() {
      setLoading(true);
      setError(null);
    });

    try {
      final repository = ref.read(landlordRepositoryProvider);
      final userId = ref.read(authProvider).user?.id;

      if (userId == null) {
        setDialogState(() {
          setLoading(false);
          setError('Sesi login tidak valid. Silakan login ulang.');
        });
        return;
      }

      // Verify password
      final isPasswordValid = await repository.verifyPassword(userId, password);

      if (!isPasswordValid) {
        setDialogState(() {
          setLoading(false);
          setError('Password salah. Silakan coba lagi.');
        });
        return;
      }

      // Password verified, proceed with deletion
      final deleted = await repository.deleteProperty(property.id);

      if (!mounted) return;
      Navigator.pop(dialogContext);

      if (deleted) {
        // Refresh both landlord dashboard and search results
        ref.invalidate(landlordProvider);
        ref.invalidate(landlordTenantsProvider);
        ref.invalidate(landlordTransactionsProvider);
        ref.invalidate(landlordReviewsProvider);
        ref.invalidate(searchProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Properti "${property.title}" berhasil dihapus.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus properti. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setDialogState(() {
        setLoading(false);
        setError('Terjadi kesalahan: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final landlordState = ref.watch(landlordProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Dasbor Landlord',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 1,
        automaticallyImplyLeading: Navigator.canPop(context),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: landlordState.when(
        data: (stats) {
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(landlordProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(context, stats),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Properti Anda',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              final authUser = ref.read(authProvider).user;
                              if (authUser == null || !authUser.isVerified) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Verifikasi Diperlukan'),
                                    content: const Text('Anda harus menyelesaikan verifikasi akun (KYC) terlebih dahulu sebelum dapat menambahkan properti.'),
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
                                        ),
                                        child: const Text('Verifikasi Sekarang', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (authUser.age == null || authUser.age == 0 ||
                                  authUser.phoneNumber == null || authUser.phoneNumber!.isEmpty ||
                                  authUser.gender == null || authUser.gender!.isEmpty ||
                                  authUser.address == null || authUser.address!.isEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LandlordProfileSetupPage(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddPropertyPage(),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Tambah'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (stats.properties.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Tidak ada properti yang dikelola.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...stats.properties.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: LandlordPropertyCard(
                              title: p.title,
                              address: p.address,
                              totalRooms: p.totalRooms,
                              occupiedRooms: p.occupiedRooms,
                              imageUrl: p.imageUrl,
                              onDelete: () => _showDeleteConfirmation(p),
                              onManageProperty: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManagePropertyPage(property: p),
                                  ),
                                ).then((_) => ref.refresh(landlordProvider));
                              },
                            ),
                          )),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
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
                  onPressed: () => ref.refresh(landlordProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, LandlordStatsModel stats) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Tarik Dana',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(stats.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Row 1: Revenue vs Withdrawn
          Row(
            children: [
              _buildMiniStat('Total Pendapatan', _formatCurrency(stats.totalRevenue)),
              Container(
                height: 30,
                width: 1,
                color: Colors.white30,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _buildMiniStat('Telah Ditarik', _formatCurrency(stats.totalWithdrawn)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Row 2: Property counts, Occupancy rate, Residents
          Row(
            children: [
              _buildMiniStat('Total Properti', stats.totalUnitsLabel),
              Container(
                height: 30,
                width: 1,
                color: Colors.white30,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _buildMiniStat('Okupansi', stats.occupancyRate),
              Container(
                height: 30,
                width: 1,
                color: Colors.white30,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _buildMiniStat('Penghuni Aktif', stats.residentsLabel),
            ],
          ),

          const SizedBox(height: 24),
          // Withdraw Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LandlordWithdrawPage(),
                  ),
                ).then((_) {
                  ref.invalidate(landlordProvider);
                  ref.invalidate(landlordTenantsProvider);
                  ref.invalidate(landlordTransactionsProvider);
                  ref.invalidate(landlordReviewsProvider);
                });
              },
              icon: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
              ),
              label: const Text(
                'Tarik Dana (Withdraw)',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
