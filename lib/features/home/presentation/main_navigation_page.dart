import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../tenant/dashboard/presentation/pages/transaction_history_page.dart';
import 'home_page.dart';
import '../../landlord/dashboard/presentation/pages/landlord_dashboard_page.dart';
import '../../landlord/dashboard/presentation/pages/landlord_tenants_page.dart';
import '../../landlord/dashboard/presentation/pages/landlord_transactions_page.dart';
import '../../landlord/dashboard/presentation/pages/landlord_reviews_page.dart';

class LandlordModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setMode(bool val) => state = val;
}
final landlordModeProvider = NotifierProvider<LandlordModeNotifier, bool>(LandlordModeNotifier.new);

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _tenantIndex = 1; // Default to HomePage (Center)
  int _landlordIndex = 0; // Default to Dashboard

  final List<Widget> _tenantPages = const [
    TransactionHistoryPage(),
    HomePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isLandlordMode = ref.watch(landlordModeProvider);

    if (!isLandlordMode) {
      // Tenant navigation layout
      return Scaffold(
        body: IndexedStack(index: _tenantIndex, children: _tenantPages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.receipt_long_rounded, 'Transaksi', false),
                  _buildNavItem(1, Icons.home_rounded, 'Home', false),
                  _buildNavItem(2, Icons.dashboard_rounded, 'Sesi Landlord', true),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Landlord navigation layout pages
      final landlordPages = [
        const LandlordDashboardPage(),
        const LandlordTenantsPage(),
        const LandlordTransactionsPage(),
        const LandlordReviewsPage(),
      ];

      return Scaffold(
        body: IndexedStack(index: _landlordIndex, children: landlordPages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLandlordNavItem(0, Icons.dashboard_rounded, 'Dasbor'),
                  _buildLandlordNavItem(1, Icons.people_rounded, 'Penyewa'),
                  _buildLandlordNavItem(2, Icons.payments_rounded, 'Penerimaan'),
                  _buildLandlordNavItem(3, Icons.star_rounded, 'Ulasan'),
                  _buildLandlordNavItem(4, Icons.home_rounded, 'Sesi Penyewa'),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isModeToggle) {
    final isSelected = !isModeToggle && _tenantIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        if (isModeToggle) {
          ref.read(landlordModeProvider.notifier).setMode(true);
          setState(() {
            _landlordIndex = 0; // reset landlord to dashboard
          });
        } else {
          setState(() => _tenantIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isModeToggle ? AppColors.accent : color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isModeToggle ? AppColors.accent : color,
                fontSize: 11,
                fontWeight: isSelected || isModeToggle ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandlordNavItem(int index, IconData icon, String label) {
    final isModeToggle = index == 4;
    final isSelected = !isModeToggle && _landlordIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        if (isModeToggle) {
          ref.read(landlordModeProvider.notifier).setMode(false);
          setState(() {
            _tenantIndex = 1; // reset tenant to Home
          });
        } else {
          setState(() => _landlordIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isModeToggle ? AppColors.accent : color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isModeToggle ? AppColors.accent : color,
                fontSize: 10,
                fontWeight: isSelected || isModeToggle ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
