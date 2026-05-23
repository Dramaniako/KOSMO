import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feature_card.dart';
import '../../auth/presentation/pages/kyc_intro_page.dart';
import '../../landlord/dashboard/presentation/pages/landlord_dashboard_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import '../../tenant/booking/presentation/pages/contract_review_page.dart';
import '../../tenant/dashboard/presentation/pages/transaction_history_page.dart';
import '../../tenant/search/presentation/pages/search_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Make status bar transparent for a modern look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final userName = "Budi"; // TODO: Fetch from AuthState

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, userName),
            _buildActiveKosBanner(context),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              sliver: _buildFeatureGrid(context),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 40), // Bottom padding
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String userName) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang,',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.surface,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveKosBanner(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sewa Aktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Jatuh tempo: 5 Jun 2026',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Residence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kamar 2A • All-Inclusive',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildMiniKosStat('Sewa Ke', '3/12'),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.white30,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _buildMiniKosStat('Sisa Hari', '20 Hari'),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.white30,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _buildMiniKosStat('Tagihan', 'Lunas'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniKosStat(String label, String value) {
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

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'title': 'Smart Search',
        'subtitle': 'Cari kos dengan filter cerdas & ketersediaan real-time',
        'icon': Icons.search_rounded,
        'route': '/search',
      },
      {
        'title': 'Verifikasi Instan',
        'subtitle': 'Proses KYC cepat dengan liveness detection',
        'icon': Icons.fingerprint_rounded,
        'route': '/kyc',
      },
      {
        'title': 'e-Signature',
        'subtitle': 'Tanda tangan kontrak digital sah & aman',
        'icon': Icons.draw_rounded,
        'route': '/contract',
      },
      {
        'title': 'Dasbor Landlord',
        'subtitle': 'Manajemen properti & bundling efisien',
        'icon': Icons.dashboard_rounded,
        'route': '/landlord-dashboard',
      },
      {
        'title': 'Riwayat Transaksi',
        'subtitle': 'Pantau tagihan & dunning system',
        'icon': Icons.receipt_long_rounded,
        'route': '/transactions',
      },
    ];

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8, // Adjusted for slightly taller cards
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final feature = features[index];
        return FeatureCard(
          title: feature['title'] as String,
          subtitle: feature['subtitle'] as String,
          icon: feature['icon'] as IconData,
          onTap: () {
            if (feature['route'] == '/kyc') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KycIntroPage()),
              );
            } else if (feature['route'] == '/search') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            } else if (feature['route'] == '/contract') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContractReviewPage(),
                ),
              );
            } else if (feature['route'] == '/landlord-dashboard') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LandlordDashboardPage(),
                ),
              );
            } else if (feature['route'] == '/transactions') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryPage(),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigasi ke ${feature['title']}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      }, childCount: features.length),
    );
  }
}
