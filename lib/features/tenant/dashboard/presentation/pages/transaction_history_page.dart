import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_card.dart';
import 'arrears_payment_page.dart';
import '../../../../landlord/dashboard/presentation/providers/landlord_provider.dart';

class TransactionHistoryPage extends ConsumerWidget {
  const TransactionHistoryPage({super.key});

  void _showTransactionDetails(BuildContext context, WidgetRef ref, TransactionModel transaction) {
    // Allow reviewing any successful transaction for testing and demo purposes
    final isStaysAtLeastOneMonth = transaction.status == TransactionStatus.success;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            transaction.invoiceNumber,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Properti', transaction.propertyName),
              _buildDetailItem('Tanggal', transaction.date),
              _buildDetailItem(
                'Tipe Transaksi',
                transaction.transactionType == 'rental' ? 'Sewa Awal' : 'Bulanan / Tunggakan',
              ),
              _buildDetailItem('Jumlah', 'Rp ${transaction.amount.toInt()}'),
              _buildDetailItem('Status', 'Sukses', Colors.green),
              if (isStaysAtLeastOneMonth && transaction.propertyId != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showWriteReviewDialog(context, ref, transaction.propertyId!, transaction.propertyName);
                    },
                    icon: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 18),
                    label: const Text(
                      'Tulis Ulasan Kos',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showWriteReviewDialog(BuildContext context, WidgetRef ref, int propertyId, String propertyName) {
    final commentController = TextEditingController();
    double rating = 5.0;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Ulasan: $propertyName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Berikan rating dan ulasan Anda untuk kos ini.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1.0;
                  return IconButton(
                    icon: Icon(
                      starVal <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.accent,
                      size: 32,
                    ),
                    onPressed: () {
                      setStateDialog(() {
                        rating = starVal;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Komentar',
                  hintText: 'Bagikan pengalaman tinggal Anda...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setStateDialog(() {
                        isSaving = true;
                      });
                      try {
                        final authState = ref.read(authProvider);
                        final userId = authState.user?.id ?? 1;
                        final success = await ref.read(propertyRepositoryProvider).addReview(
                              propertyId: propertyId,
                              userId: userId,
                              rating: rating,
                              comment: commentController.text.trim(),
                            );
                        if (success) {
                          ref.invalidate(landlordReviewsProvider);
                          ref.invalidate(propertiesListProvider);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ulasan berhasil dikirim! Terima kasih.'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          throw Exception('Gagal menyimpan ulasan.');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        setStateDialog(() {
                          isSaving = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Kirim', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Tagihan', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        automaticallyImplyLeading: Navigator.canPop(context),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: transactionState.when(
        data: (transactions) {
          final pendingTransactions = transactions.where((t) => t.status != TransactionStatus.success).toList();
          final successTransactions = transactions.where((t) => t.status == TransactionStatus.success).toList();

          final failedArrears = transactions.cast<TransactionModel?>().firstWhere(
            (t) => t != null && t.status == TransactionStatus.failed && t.transactionType == 'arrears',
            orElse: () => null,
          );
          final hasFailedArrears = failedArrears != null;

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(transactionProvider.future),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasFailedArrears) _buildDunningBanner(context, ref, failedArrears),

                    if (pendingTransactions.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Text(
                          'Tagihan Aktif / Tertunda',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      ...pendingTransactions.map((t) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: TransactionCard(
                              date: t.date,
                              invoiceNumber: t.invoiceNumber,
                              amount: t.amount,
                              status: t.status,
                              propertyName: t.propertyName,
                              onPay: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ArrearsPaymentPage(transaction: t)),
                                );
                              },
                            ),
                          )),
                    ],

                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        'Riwayat Transaksi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    if (successTransactions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Tidak ada riwayat transaksi.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...successTransactions.map((t) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: GestureDetector(
                              onTap: () => _showTransactionDetails(context, ref, t),
                              child: TransactionCard(
                                date: t.date,
                                invoiceNumber: t.invoiceNumber,
                                amount: t.amount,
                                status: t.status,
                                propertyName: t.propertyName,
                              ),
                            ),
                          )),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  onPressed: () => ref.refresh(transactionProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDunningBanner(BuildContext context, WidgetRef ref, TransactionModel transaction) {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArrearsPaymentPage(transaction: transaction)),
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
