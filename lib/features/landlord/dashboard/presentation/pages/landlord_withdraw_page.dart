import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/withdrawal_model.dart';
import '../providers/landlord_provider.dart';

final withdrawalsProvider = FutureProvider.autoDispose<List<WithdrawalModel>>((ref) async {
  final repository = ref.watch(landlordRepositoryProvider);
  final authState = ref.watch(authProvider);
  final ownerId = authState.user?.id ?? 2;
  return repository.getWithdrawals(ownerId);
});

class LandlordWithdrawPage extends ConsumerStatefulWidget {
  const LandlordWithdrawPage({super.key});

  @override
  ConsumerState<LandlordWithdrawPage> createState() => _LandlordWithdrawPageState();
}

class _LandlordWithdrawPageState extends ConsumerState<LandlordWithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedBank = 'BCA';

  final List<String> _banks = ['BCA', 'Mandiri', 'BNI', 'BRI', 'Permata'];

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
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
    return 'Rp ${buffer.toString()}';
  }

  void _simulateWithdrawal(double maxBalance) {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 || amount > maxBalance) return;

    // Show simulated process dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _WithdrawalProgressDialog(
        bankName: _selectedBank,
        accountNumber: _accountController.text,
        amount: amount,
        onSuccess: () async {
          // Save to database
          final repository = ref.read(landlordRepositoryProvider);
          final authState = ref.read(authProvider);
          final ownerId = authState.user?.id ?? 2;

          await repository.requestWithdrawal(
            landlordId: ownerId,
            amount: amount,
            bankName: _selectedBank,
            accountNumber: _accountController.text,
          );

          // Refresh states
          ref.invalidate(landlordProvider);
          ref.invalidate(landlordTenantsProvider);
          ref.invalidate(landlordTransactionsProvider);
          ref.invalidate(landlordReviewsProvider);
          ref.invalidate(withdrawalsProvider);

          if (mounted) {
            // Reset form
            _accountController.clear();
            _amountController.clear();
            setState(() {});
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final landlordState = ref.watch(landlordProvider);
    final withdrawalsState = ref.watch(withdrawalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tarik Dana', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: landlordState.when(
        data: (stats) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Balance Info Card
                  Container(
                    width: double.infinity,
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
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Terkumpul Yang Bisa Ditarik',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(stats.balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Batas maksimum penarikan adalah saldo aktif saat ini.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 2. Withdrawal Form Card
                  const Text(
                    'Formulir Penarikan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bank Selector Dropdown
                          const Text(
                            'Bank Tujuan',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBank,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.account_balance_rounded, color: AppColors.primary),
                            ),
                            items: _banks.map((bank) {
                              return DropdownMenuItem(
                                value: bank,
                                child: Text(bank, style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedBank = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Account Number
                          const Text(
                            'Nomor Rekening',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _accountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: 'Masukkan nomor rekening Anda',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nomor rekening wajib diisi';
                              }
                              if (val.trim().length < 8) {
                                return 'Nomor rekening minimal 8 digit';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Amount field
                          const Text(
                            'Jumlah Penarikan (Rp)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: 'Contoh: 100000',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.primary),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Jumlah penarikan wajib diisi';
                              }
                              final amt = double.tryParse(val);
                              if (amt == null || amt <= 0) {
                                return 'Jumlah penarikan tidak valid';
                              }
                              if (amt > stats.balance) {
                                return 'Jumlah melebihi saldo aktif Anda';
                              }
                              if (amt < 50000) {
                                return 'Minimal penarikan adalah Rp 50.000';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: stats.balance >= 50000
                                  ? () => _simulateWithdrawal(stats.balance)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Proses Penarikan Dana', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. History Section
                  const Text(
                    'Riwayat Penarikan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  withdrawalsState.when(
                    data: (withdrawals) {
                      if (withdrawals.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada riwayat penarikan.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: withdrawals.length,
                        itemBuilder: (context, index) {
                          final item = withdrawals[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Transfer ke ${item.bankName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rek. ${item.accountNumber}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.dateStr,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatCurrency(item.amount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Berhasil',
                                        style: TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    )),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Gagal memuat riwayat: $err', style: const TextStyle(color: AppColors.error)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(err.toString(), style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

class _WithdrawalProgressDialog extends StatefulWidget {
  final String bankName;
  final String accountNumber;
  final double amount;
  final VoidCallback onSuccess;

  const _WithdrawalProgressDialog({
    required this.bankName,
    required this.accountNumber,
    required this.amount,
    required this.onSuccess,
  });

  @override
  State<_WithdrawalProgressDialog> createState() => _WithdrawalProgressDialogState();
}

class _WithdrawalProgressDialogState extends State<_WithdrawalProgressDialog> {
  int _step = 0;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() async {
    // Step 0: Validating account
    setState(() {
      _step = 0;
      _progress = 0.2;
    });
    await Future.delayed(const Duration(milliseconds: 1000));

    // Step 1: Processing Transfer
    if (!mounted) return;
    setState(() {
      _step = 1;
      _progress = 0.6;
    });
    await Future.delayed(const Duration(milliseconds: 1500));

    // Step 2: Finalizing/Saving
    if (!mounted) return;
    setState(() {
      _step = 2;
      _progress = 1.0;
    });
    
    // Call onSuccess database operations
    widget.onSuccess();
    
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    Navigator.pop(context); // close simulation dialog

    // Show beautiful success dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 64),
            ),
            const SizedBox(height: 20),
            const Text(
              'Penarikan Berhasil',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Dana sebesar ${_formatCurrency(widget.amount)} telah berhasil ditransfer ke rekening ${widget.bankName} (${widget.accountNumber}).',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
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
    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    String stepText = '';
    switch (_step) {
      case 0:
        stepText = 'Memvalidasi rekening bank tujuan...';
        break;
      case 1:
        stepText = 'Memproses pengiriman transfer dana...';
        break;
      case 2:
        stepText = 'Transfer selesai! Mengupdate saldo...';
        break;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              stepText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
