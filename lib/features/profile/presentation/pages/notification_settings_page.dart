import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Push Notifications State
  bool _pushBilling = true;
  bool _pushRenting = true;
  bool _pushPromo = false;

  // Email Notifications State
  bool _emailReceipt = true;
  bool _emailReport = false;

  // WhatsApp Alerts State
  bool _waDunning = true;

  bool _isSaving = false;

  void _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    // Simulate saving settings to shared preferences or database
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengaturan notifikasi berhasil disimpan.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Notifikasi', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: _isSaving
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Menyimpan pengaturan...',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola Notifikasi Anda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih saluran notifikasi yang ingin Anda aktifkan untuk aktivitas Kosmo.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // Section 1: Push Notifications
                    _buildSectionHeader('Notifikasi Push (Aplikasi)'),
                    _buildSwitchTile(
                      title: 'Tagihan & Pembayaran',
                      subtitle: 'Dapatkan pemberitahuan saat tagihan baru terbit atau pembayaran berhasil.',
                      value: _pushBilling,
                      onChanged: (val) => setState(() => _pushBilling = val),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildSwitchTile(
                      title: 'Status Kamar & Sewa',
                      subtitle: 'Informasi perubahan masa aktif sewa atau status okupansi kamar.',
                      value: _pushRenting,
                      onChanged: (val) => setState(() => _pushRenting = val),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildSwitchTile(
                      title: 'Promo & Info Menarik',
                      subtitle: 'Tips hunian co-living pintar dan penawaran diskon sewa dari Kosmo.',
                      value: _pushPromo,
                      onChanged: (val) => setState(() => _pushPromo = val),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Email Notifications
                    _buildSectionHeader('Notifikasi Email'),
                    _buildSwitchTile(
                      title: 'Kuitansi Pembayaran',
                      subtitle: 'Kirim bukti/kuitansi transaksi resmi dalam format PDF ke email Anda.',
                      value: _emailReceipt,
                      onChanged: (val) => setState(() => _emailReceipt = val),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildSwitchTile(
                      title: 'Laporan Finansial Bulanan',
                      subtitle: 'Laporan rekapitulasi transaksi sewa bulanan (khusus landlord).',
                      value: _emailReport,
                      onChanged: (val) => setState(() => _emailReport = val),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: WhatsApp Alerts
                    _buildSectionHeader('Alert WhatsApp'),
                    _buildSwitchTile(
                      title: 'Peringatan Jatuh Tempo',
                      subtitle: 'Kirim pengingat tagihan jatuh tempo atau tagihan arrears via chat WhatsApp.',
                      value: _waDunning,
                      onChanged: (val) => setState(() => _waDunning = val),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Simpan Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: AppColors.surface,
      child: SwitchListTile.adaptive(
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
