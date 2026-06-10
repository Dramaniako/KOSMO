import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../../presentation/widgets/transaction_card.dart';

class ArrearsPaymentPage extends ConsumerStatefulWidget {
  final TransactionModel transaction;

  const ArrearsPaymentPage({
    super.key,
    required this.transaction,
  });

  @override
  ConsumerState<ArrearsPaymentPage> createState() => _ArrearsPaymentPageState();
}

class _ArrearsPaymentPageState extends ConsumerState<ArrearsPaymentPage> with TickerProviderStateMixin {
  String _selectedMethod = 'va'; // 'va', 'gopay', 'card'
  String _selectedBank = 'bca'; // 'bca', 'mandiri', 'bni'
  
  // Card inputs
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isProcessing = false;
  int _processStage = 0;
  bool _otpRequested = false;
  String _vaNumber = '';
  int _secondsLeft = 900;
  Timer? _countdownTimer;
  Timer? _processingTimer;

  late AnimationController _qrLaserController;

  final List<String> _stages = [
    'Menghubungkan ke secure payment gateway...',
    'Memproses verifikasi tagihan penunggakan...',
    'Mengonfirmasi status pelunasan dengan server...',
    'Mengirim data pembaruan ke database...',
    'Selesai! Tagihan Anda berhasil dilunasi.'
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _qrLaserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    final vaSuffix = List.generate(11, (_) => Random().nextInt(10).toString()).join();
    _vaNumber = '80777$vaSuffix';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _processingTimer?.cancel();
    _qrLaserController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        _showTimeoutAlert();
      }
    });
  }

  void _showTimeoutAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Kedaluwarsa'),
        content: const Text('Waktu pembayaran tagihan Anda telah habis.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  String _getFormattedTime() {
    final int minutes = _secondsLeft ~/ 60;
    final int seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
    return buffer.toString();
  }

  void _onPayPressed() {
    if (_selectedMethod == 'card') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_selectedMethod == 'gopay') {
      _qrLaserController.repeat(reverse: true);
    }

    setState(() {
      _isProcessing = true;
      _processStage = 0;
    });

    // We immediately show the interactive checkout portal or simulated success process.
    // Let's make it show the processing state once they click confirm in sandbox.
  }

  void _simulatePaymentSuccess() {
    setState(() {
      _isProcessing = true;
      _processStage = 0;
    });

    _processingTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) return;
      if (_processStage < _stages.length - 1) {
        setState(() {
          _processStage++;
        });
      } else {
        timer.cancel();
        
        // Execute database updates through notifier
        ref.read(transactionProvider.notifier).payArrears(widget.transaction.invoiceNumber);

        // Pop all back to TransactionHistoryPage with a success banner
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pembayaran tagihan ${widget.transaction.invoiceNumber} berhasil dilunasi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return _buildProcessingScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bayar Tagihan Menunggak', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              _buildSummaryCard(),

              const SizedBox(height: 24),

              const Text(
                'Pilih Metode Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              _buildMethodSelector(
                id: 'va',
                title: 'Virtual Account (Transfer VA)',
                subtitle: 'BCA, Mandiri, BNI (Verifikasi Otomatis)',
                icon: Icons.account_balance_wallet_rounded,
              ),
              _buildMethodSelector(
                id: 'gopay',
                title: 'GoPay / QRIS',
                subtitle: 'Bayar instan dengan aplikasi pembayaran pilihan Anda',
                icon: Icons.qr_code_2_rounded,
              ),
              _buildMethodSelector(
                id: 'card',
                title: 'Kartu Kredit / Debit',
                subtitle: 'Visa, MasterCard, JCB',
                icon: Icons.credit_card_rounded,
              ),

              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildDetailsForm(),
              ),

              const SizedBox(height: 32),

              // Simulation helper sandbox panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.science_rounded, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'SIMULASI SECURE GATEWAY (SANDBOX)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _simulatePaymentSuccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        label: const Text(
                          'Simulasikan Bayar Sukses',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RINCIAN TUNGGAKAN',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_rounded, color: AppColors.error, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _getFormattedTime(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.transaction.propertyName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Nomor Tagihan: ${widget.transaction.invoiceNumber}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pelunasan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                'Rp ${_formatCurrency(widget.transaction.amount)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsForm() {
    if (_selectedMethod == 'va') {
      final bankName = _selectedBank.toUpperCase();
      return Container(
        key: const ValueKey('va'),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Bank Transfer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBankLogoBtn('bca', 'BCA'),
                const SizedBox(width: 12),
                _buildBankLogoBtn('mandiri', 'Mandiri'),
                const SizedBox(width: 12),
                _buildBankLogoBtn('bni', 'BNI'),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Virtual Account $bankName',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    bankName,
                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('NOMOR VIRTUAL ACCOUNT', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _vaNumber,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _vaNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor Virtual Account disalin ke clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                  label: const Text('Salin', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_selectedMethod == 'gopay') {
      return Container(
        key: const ValueKey('gopay'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Text('SCAN KODE QRIS UNTUK BAYAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12, width: 1.5),
              ),
              child: CustomPaint(
                painter: _MockQRPainter(0.5),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan pindai QRIS di atas dengan aplikasi e-wallet Anda.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    } else {
      // Credit Card
      return Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('card'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Nama Pemilik Kartu',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              validator: (val) => val == null || val.isEmpty ? 'Nama harus diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor Kartu',
                hintText: '4000 1234 5678 9010',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              validator: (val) => val == null || val.length < 16 ? 'Nomor kartu tidak valid' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cardExpiryController,
                    decoration: const InputDecoration(
                      labelText: 'Masa Berlaku (MM/YY)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (val) => val == null || !val.contains('/') ? 'MM/YY' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cardCvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (val) => val == null || val.length < 3 ? 'CVV' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_otpRequested) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _otpRequested = true;
                      });
                    }
                  },
                  child: const Text('Kirim OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ] else ...[
              TextFormField(
                controller: _otpController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kode OTP Verifikasi',
                  hintText: 'Masukkan 123456',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_otpController.text == '123456' || _otpController.text.length == 6) {
                      _simulatePaymentSuccess();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP Salah! Gunakan "123456"')),
                      );
                    }
                  },
                  child: const Text('Verifikasi OTP & Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ]
          ],
        ),
      );
    }
  }

  Widget _buildBankLogoBtn(String bankId, String label) {
    final isSelected = _selectedBank == bankId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBank = bankId;
          });
        },
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
              const SizedBox(height: 24),
              const Text(
                'Menyelesaikan Pembayaran',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _stages[_processStage],
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple Neon QR Painter for dynamic mock QR display
class _MockQRPainter extends CustomPainter {
  final double sweepProgress;
  _MockQRPainter(this.sweepProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final double anchorSize = 30.0;
    final double padding = 4.0;

    // Top-Left Anchor
    canvas.drawRect(Rect.fromLTWH(padding, padding, anchorSize, anchorSize), borderPaint);
    canvas.drawRect(Rect.fromLTWH(padding + 6, padding + 6, anchorSize - 12, anchorSize - 12), Paint()..color = Colors.black);

    // Top-Right Anchor
    canvas.drawRect(Rect.fromLTWH(size.width - anchorSize - padding, padding, anchorSize, anchorSize), borderPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - anchorSize - padding + 6, padding + 6, anchorSize - 12, anchorSize - 12), Paint()..color = Colors.black);

    // Bottom-Left Anchor
    canvas.drawRect(Rect.fromLTWH(padding, size.height - anchorSize - padding, anchorSize, anchorSize), borderPaint);
    canvas.drawRect(Rect.fromLTWH(padding + 6, size.height - anchorSize - padding + 6, anchorSize - 12, anchorSize - 12), Paint()..color = Colors.black);

    final random = Random(42);
    final matrixPaint = Paint()..color = Colors.black87;
    final double cellSize = 6.0;

    for (double y = padding; y < size.height - padding; y += cellSize) {
      for (double x = padding; x < size.width - padding; x += cellSize) {
        if ((x < anchorSize + padding && y < anchorSize + padding) ||
            (x > size.width - anchorSize - padding - 6 && y < anchorSize + padding) ||
            (x < anchorSize + padding && y > size.height - anchorSize - padding - 6)) {
          continue;
        }
        if (x > size.width / 2 - 15 && x < size.width / 2 + 15 &&
            y > size.height / 2 - 15 && y < size.height / 2 + 15) {
          continue;
        }
        if (random.nextDouble() > 0.45) {
          canvas.drawRect(Rect.fromLTWH(x + 0.5, y + 0.5, cellSize - 1, cellSize - 1), matrixPaint);
        }
      }
    }

    final centerBadgePaint = Paint()..color = Colors.blue.shade900;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 16, size.height / 2 - 12, 32, 24),
        const Radius.circular(4),
      ),
      centerBadgePaint,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'QR',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width / 2 - 7, size.height / 2 - 6));
  }

  @override
  bool shouldRepaint(covariant _MockQRPainter oldDelegate) => false;
}
