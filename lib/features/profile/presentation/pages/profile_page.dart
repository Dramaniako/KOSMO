import 'package:flutter/material.dart';
import '../../../../core/services/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 32),
              
              // Menu Sections
              _buildSectionTitle('Akun'),
              _buildMenuTile(context, Icons.payment_rounded, 'Metode Pembayaran', 'Kartu Kredit, Virtual Account'),
              _buildMenuTile(context, Icons.lock_outline_rounded, 'Ganti Kata Sandi', null),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Pengaturan'),
              _buildMenuTile(context, Icons.notifications_none_rounded, 'Notifikasi', 'Aktif'),
              _buildMenuTile(context, Icons.language_rounded, 'Bahasa', 'Indonesia'),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Bantuan & Informasi'),
              _buildMenuTile(context, Icons.help_outline_rounded, 'Pusat Bantuan', null),
              _buildMenuTile(context, Icons.description_outlined, 'Syarat & Ketentuan', null),
              
              const SizedBox(height: 40),
              
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logout berhasil.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Keluar (Logout)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.person_rounded, size: 60, color: AppColors.textSecondary),
              ),
            ),
            // Edit icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name and Email
        const Text(
          'Budi Santoso',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'budi.santoso@email.com • +62 812-3456-7890',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        // KYC Badge
        ValueListenableBuilder<bool>(
          valueListenable: AppState().isVerifiedNotifier,
          builder: (context, isVerified, child) {
            final badgeColor = isVerified ? AppColors.secondary : AppColors.textSecondary;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVerified ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                    color: badgeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isVerified ? 'Akun Terverifikasi' : 'Belum Terverifikasi',
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, String? subtitle) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Membuka menu: $title')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}
