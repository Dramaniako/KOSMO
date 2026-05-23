import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../widgets/transaction_card.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Tagihan', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        automaticallyImplyLeading: Navigator.canPop(context),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDunningBanner(context),
              
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  'Tagihan Bulan Ini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: TransactionCard(
                  date: '5 Mei 2026',
                  invoiceNumber: 'INV-KSM-0526-001',
                  amount: 4500000.0,
                  status: TransactionStatus.failed,
                  propertyName: 'Premium Residence (Kamar 2A)',
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Text(
                  'Riwayat Sebelumnya',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: TransactionCard(
                  date: '5 Apr 2026',
                  invoiceNumber: 'INV-KSM-0426-001',
                  amount: 4500000.0,
                  status: TransactionStatus.success,
                  propertyName: 'Premium Residence (Kamar 2A)',
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: TransactionCard(
                  date: '5 Mar 2026',
                  invoiceNumber: 'INV-KSM-0326-001',
                  amount: 4500000.0,
                  status: TransactionStatus.success,
                  propertyName: 'Premium Residence (Kamar 2A)',
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDunningBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Auto-Debit Gagal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Sistem gagal menarik saldo dari kartu Anda untuk langganan bulan ini. Silakan lakukan pembayaran manual untuk menghindari denda atau penangguhan.',
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Membuka Payment Gateway...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
