import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../dashboard/data/models/transaction_model.dart';
import '../../../dashboard/presentation/providers/transaction_provider.dart';
import '../../../dashboard/presentation/widgets/transaction_card.dart';
import 'contract_success_page.dart';

class PaymentGatewayPortalPage extends ConsumerStatefulWidget {
  final double amount;
  final String paymentMethod;
  final String? bankCode;
  final List<Offset?>? signaturePoints;

  const PaymentGatewayPortalPage({
    super.key,
    required this.amount,
    required this.paymentMethod,
    this.bankCode,
    this.signaturePoints,
  });

  @override
  ConsumerState<PaymentGatewayPortalPage> createState() => _PaymentGatewayPortalPageState();
}

class _PaymentGatewayPortalPageState extends ConsumerState<PaymentGatewayPortalPage> with TickerProviderStateMixin {
  int _secondsLeft = 900; // 15:00 mins countdown
  Timer? _countdownTimer;
  bool _isProcessing = false;
  int _processStage = 0;
  Timer? _processingTimer;

  // QR Sweep laser animation
  late AnimationController _qrLaserController;

  // Credit card OTP fields
  final _otpController = TextEditingController();
  bool _otpRequested = false;

  // Persistent Virtual Account number
  String _vaNumber = '';

  final List<String> _stages = [
    'Menghubungkan ke server bank penerbit...',
    'Memvalidasi dana dan otorisasi transaksi...',
    'Mengonfirmasi tanda tangan kontrak & E-Meterai...',
    'Menyelesaikan transaksi pembayaran...',
    'Selesai! Kontrak Anda sekarang aktif.'
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _qrLaserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.paymentMethod == 'gopay') {
      _qrLaserController.repeat(reverse: true);
    }

    if (widget.paymentMethod == 'va') {
      final vaSuffix = List.generate(11, (_) => Random().nextInt(10).toString()).join();
      _vaNumber = '80777$vaSuffix';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _processingTimer?.cancel();
    _qrLaserController.dispose();
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
        content: const Text('Waktu pembayaran Anda telah habis. Silakan buat pesanan baru.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Kembali ke Beranda'),
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

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  void _simulatePaymentSuccess() {
    setState(() {
      _isProcessing = true;
      _processStage = 0;
    });

    _processingTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) return;
      if (_processStage < _stages.length - 1) {
        setState(() {
          _processStage++;
        });
      } else {
        timer.cancel();
        
        // Add new transaction to provider
        final now = DateTime.now();
        final dateString = '${now.day} ${_getMonthName(now.month)} ${now.year}';
        final invoiceSuffix = (100 + Random().nextInt(900)).toString(); // Random 3 digits
        final newInvoice = 'INV-KSM-0526-$invoiceSuffix';

        final newTransaction = TransactionModel(
          date: dateString,
          invoiceNumber: newInvoice,
          amount: widget.amount,
          status: TransactionStatus.success,
          propertyName: 'Premium Residence (Kamar 2A)',
        );

        ref.read(transactionProvider.notifier).addTransaction(newTransaction);

        // Redirect to Success Contract Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ContractSuccessPage(
              signaturePoints: widget.signaturePoints,
            ),
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
        title: const Text('Gateway Pembayaran', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        automaticallyImplyLeading: false, // Disallow going back to avoid payment double-clicks
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top portal header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              color: Colors.blue.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'KOSMO SECURE GATEWAY',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.lock_rounded, color: Colors.greenAccent, size: 12),
                      SizedBox(width: 4),
                      Text('Secure 256-Bit SSL', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Timer & Amount summary
                    _buildTimerHeader(),

                    const SizedBox(height: 24),

                    // Payment details container
                    _buildPaymentInterface(),

                    const SizedBox(height: 32),

                    // Simulation Helper Actions
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
                                'SIMULASI TRANSAKSI SANDBOX',
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
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              child: const Text('Batalkan Transaksi', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              const Text('TOTAL BIAYA', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              const SizedBox(height: 4),
              Text(
                'Rp ${widget.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('BATAS WAKTU', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _getFormattedTime(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInterface() {
    if (widget.paymentMethod == 'va') {
      final bankName = widget.bankCode?.toUpperCase() ?? 'BCA';
      final vaNumber = _vaNumber;

      return Container(
        padding: const EdgeInsets.all(24),
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
                Text(
                  'Virtual Account $bankName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    bankName,
                    style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('NOMOR VIRTUAL ACCOUNT', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vaNumber,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.5),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: vaNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor Virtual Account disalin ke clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Salin', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Petunjuk Transfer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildAccordionStep('1. Masuk ke M-Banking / ATM Bank Anda.'),
            _buildAccordionStep('2. Pilih menu "Transfer" lalu klik "Virtual Account".'),
            _buildAccordionStep('3. Masukkan kode pembayaran di atas dan pastikan nama penerima adalah "KOSMO INDONESIA".'),
            _buildAccordionStep('4. Masukkan nominal tagihan Rp 4.550.000,- secara tepat lalu konfirmasi pin Anda.'),
          ],
        ),
      );
    } else if (widget.paymentMethod == 'gopay') {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Text('SCAN KODE QRIS GOPAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text(
              'Gunakan aplikasi Gojek, OVO, ShopeePay atau LinkAja Anda untuk memindai.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Custom Painted QR Code with glowing sweeping laser line
            Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: AnimatedBuilder(
                animation: _qrLaserController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MockQRPainter(_qrLaserController.value),
                    size: Size.infinite,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Menunggu pembayaran dari perangkat Anda...',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ],
            )
          ],
        ),
      );
    } else {
      // Credit Card OTP Validation Portal
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Text('3D-Secure Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Demi keamanan, silakan verifikasi transaksi kartu Anda dengan memasukkan kode OTP 6 digit yang telah kami kirimkan ke nomor HP terdaftar Anda.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),

            if (!_otpRequested) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _otpRequested = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kode verifikasi OTP berhasil dikirim! (Coba masukkan: 123456)')),
                    );
                  },
                  child: const Text('Kirim Kode OTP SMS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Masukkan Kode OTP',
                  hintText: 'xxxxxx',
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
                        const SnackBar(content: Text('Kode OTP salah! Coba masukkan "123456"')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Verifikasi OTP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildAccordionStep(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        step,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
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
            color: Colors.grey.shade900.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Menyelesaikan Pembayaran',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _stages[_processStage],
                  key: ValueKey<int>(_processStage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter to draw a highly detailed neon-style QRIS box
class _MockQRPainter extends CustomPainter {
  final double sweepProgress;

  _MockQRPainter(this.sweepProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    // 1. Draw QR code anchors (Outer Corner Squares)
    final double anchorSize = 40.0;
    final double padding = 8.0;

    // Top-Left Anchor
    canvas.drawRect(Rect.fromLTWH(padding, padding, anchorSize, anchorSize), borderPaint);
    canvas.drawRect(Rect.fromLTWH(padding + 8, padding + 8, anchorSize - 16, anchorSize - 16), Paint()..color = Colors.black);

    // Top-Right Anchor
    canvas.drawRect(Rect.fromLTWH(size.width - anchorSize - padding, padding, anchorSize, anchorSize), borderPaint);
    canvas.drawRect(Rect.fromLTWH(size.width - anchorSize - padding + 8, padding + 8, anchorSize - 16, anchorSize - 16), Paint()..color = Colors.black);

    // Bottom-Left Anchor
    canvas.drawRect(Rect.fromLTWH(padding, size.height - anchorSize - padding, anchorSize, anchorSize), borderPaint);
    canvas.drawRect(Rect.fromLTWH(padding + 8, size.height - anchorSize - padding + 8, anchorSize - 16, anchorSize - 16), Paint()..color = Colors.black);

    // 2. Draw mock pixel blocks (QR Matrix)
    final random = Random(42); // Seed to keep the QR pattern static
    final matrixPaint = Paint()..color = Colors.black87;
    final double cellSize = 8.0;

    for (double y = padding; y < size.height - padding; y += cellSize) {
      for (double x = padding; x < size.width - padding; x += cellSize) {
        // Exclude anchor squares area
        if ((x < anchorSize + padding && y < anchorSize + padding) ||
            (x > size.width - anchorSize - padding - 8 && y < anchorSize + padding) ||
            (x < anchorSize + padding && y > size.height - anchorSize - padding - 8)) {
          continue;
        }

        // Draw center logo exclusion
        if (x > size.width / 2 - 20 && x < size.width / 2 + 20 &&
            y > size.height / 2 - 20 && y < size.height / 2 + 20) {
          continue;
        }

        // Random matrix blocks
        if (random.nextDouble() > 0.45) {
          canvas.drawRect(Rect.fromLTWH(x + 1, y + 1, cellSize - 2, cellSize - 2), matrixPaint);
        }
      }
    }

    // 3. Draw Center GoPay/QRIS Badge
    final centerBadgePaint = Paint()
      ..color = Colors.blue.shade900
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width / 2 - 24, size.height / 2 - 16, 48, 32),
        const Radius.circular(6),
      ),
      centerBadgePaint,
    );

    // Draw little letters "G" inside the center badge
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'QR',
        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width / 2 - 11, size.height / 2 - 8));

    // 4. Draw Glowing Sweep Laser Line
    final double laserY = padding + sweepProgress * (size.height - padding * 2);
    final laserPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    
    // Add glow under the laser
    final glowPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(padding, max(padding, laserY - 8), size.width - padding, min(size.height - padding, laserY + 8)),
      glowPaint,
    );

    canvas.drawLine(Offset(padding, laserY), Offset(size.width - padding, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant _MockQRPainter oldDelegate) {
    return oldDelegate.sweepProgress != sweepProgress;
  }
}
