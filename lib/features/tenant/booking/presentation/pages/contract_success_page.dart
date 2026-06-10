import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/providers/shared_preferences_provider.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../search/data/models/room_model.dart';
import '../../../search/domain/entities/property_entity.dart';

class ContractSuccessPage extends ConsumerStatefulWidget {
  final PropertyEntity property;
  final RoomModel room;
  final List<Offset?>? signaturePoints;

  const ContractSuccessPage({
    super.key,
    required this.property,
    required this.room,
    this.signaturePoints,
  });

  @override
  ConsumerState<ContractSuccessPage> createState() => _ContractSuccessPageState();
}

class _ContractSuccessPageState extends ConsumerState<ContractSuccessPage> {
  bool _isExporting = true;
  double _exportProgress = 0.0;
  int _stageIndex = 0;
  Timer? _timer;

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

  late String _tenantName;
  late String _tenantNik;
  late String _tenantAddress;

  final List<String> _stages = [
    'Mempersiapkan lembar kontrak...',
    'Menyematkan data biometrik penyewa...',
    'Menempelkan E-Signature & Meterai Digital...',
    'Mengenkripsi dokumen kontrak...',
    'Selesai!'
  ];

  @override
  void initState() {
    super.initState();

    // Retrieve user and KTP details from preferences and authProvider
    final userName = ref.read(authProvider).user?.name ?? 'Budi Santoso';
    _tenantName = userName.toUpperCase();

    final prefs = ref.read(sharedPreferencesProvider);
    _tenantNik = prefs.getString('ktp_nik') ?? '3174092408970001';
    _tenantAddress = prefs.getString('ktp_address') ??
        'JL. SETIABUDI TENGAH NO. 12, RT 005/RW 001, JAKARTA SELATAN';

    _startExportingProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startExportingProgress() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (_exportProgress < 1.0) {
        setState(() {
          _exportProgress += 0.02; // ~2.5 seconds total
          if (_exportProgress < 0.25) {
            _stageIndex = 0;
          } else if (_exportProgress < 0.50) {
            _stageIndex = 1;
          } else if (_exportProgress < 0.75) {
            _stageIndex = 2;
          } else {
            _stageIndex = 3;
          }
        });
      } else {
        timer.cancel();
        setState(() {
          _stageIndex = 4;
          _isExporting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isExporting) {
      return _buildExportingLoader();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kontrak Sewa', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Success Icon & Title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.secondary,
                  size: 56,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kontrak Sewa Sah!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dokumen kontrak Anda telah berhasil ditandatangani secara digital dan sah di bawah hukum.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              
              const SizedBox(height: 24),

              // Interactive Contract PDF Mockup
              _buildContractDocument(),

              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate back to the main navigation screen (Home)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home_rounded, color: Colors.white),
                  label: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kontrak PDF berhasil diunduh ke folder Dokumen!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                  label: const Text(
                    'Unduh PDF Kontrak',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportingLoader() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Loader
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: _exportProgress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Text(
                    '${(_exportProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Mengekspor Kontrak Sewa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _stages[_stageIndex],
                  key: ValueKey<int>(_stageIndex),
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

  Widget _buildContractDocument() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Center(
            child: Column(
              children: [
                Text(
                  'SURAT PERJANJIAN SEWA MENYEWA',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'PROPERTI KOSMO',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Divider(color: Colors.black54, thickness: 1),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pihak Pertama
          const Text(
            'PIHAK PERTAMA (Pemilik Kos)',
            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'KOSMO MANAGEMENT',
            style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Alamat: Jl. Setiabudi Tengah No. 12, Jakarta',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          
          const SizedBox(height: 16),

          // Pihak Kedua
          const Text(
            'PIHAK KEDUA (Penyewa Kos)',
            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _tenantName,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          Text(
            'NIK: $_tenantNik',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          Text(
            'Alamat: $_tenantAddress',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.black12),
          const SizedBox(height: 8),

          // Objek Sewa
          const Text(
            'PASAL 1: OBJEK & KETENTUAN',
            style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Sewa menyewa dilangsungkan untuk jangka waktu 1 bulan, terhitung dari tanggal pembayaran pertama untuk ${widget.property.title} (${widget.room.roomNumber}). Harga sewa yang disepakati adalah sebesar Rp ${_formatCurrency(widget.property.price)},- / bulan dengan sistem ${widget.property.isAllInclusive ? "All-Inclusive" : "tidak termasuk air/listrik"}.',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.justify,
          ),

          const SizedBox(height: 24),

          // Signatures Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Landlord Signature Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'PIHAK PERTAMA',
                      style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Mock Stamp/Seal & Handwriting
                    Container(
                      height: 60,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.approval_rounded,
                            size: 44,
                            color: Colors.blue.withValues(alpha: 0.15),
                          ),
                          const Text(
                            'KOSMO Mgmt',
                            style: TextStyle(
                              color: Colors.blue,
                              fontFamily: 'Courier',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'KOSMO Management',
                      style: TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Tenant Signature Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'PIHAK KEDUA',
                      style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // Actual Scaled Signature Paint Block
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Meterai Stamp Mock
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              border: Border.all(color: Colors.blue.shade300, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Column(
                              children: [
                                Text('METERAI', style: TextStyle(color: Colors.blue, fontSize: 5, fontWeight: FontWeight.bold)),
                                Text('TEMPEL', style: TextStyle(color: Colors.blue, fontSize: 4)),
                                Text('Rp 10.000', style: TextStyle(color: Colors.blue, fontSize: 5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        // Signature Preview
                        if (widget.signaturePoints != null && widget.signaturePoints!.isNotEmpty)
                          SignaturePreviewWidget(points: widget.signaturePoints!)
                        else
                          Container(
                            height: 60,
                            color: Colors.grey.shade100,
                            alignment: Alignment.center,
                            child: const Text('No Signature', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _tenantName,
                      style: const TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 8),

          // Digital verification stamp
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, size: 28, color: Colors.grey.shade400),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'DOKUMEN DITANDATANGANI SECARA ELEKTRONIK',
                    style: TextStyle(fontSize: 7, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Verifikasi keaslian dokumen via KOSMO Blockchain Ledger',
                    style: TextStyle(fontSize: 6, color: Colors.grey),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

// Bounding box scaler & Mini Signature Painter
class SignaturePreviewWidget extends StatelessWidget {
  final List<Offset?> points;
  const SignaturePreviewWidget({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 60,
      color: Colors.transparent,
      child: CustomPaint(
        painter: _SignatureMiniPainter(points),
        size: Size.infinite,
      ),
    );
  }
}

class _SignatureMiniPainter extends CustomPainter {
  final List<Offset?> points;
  _SignatureMiniPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 1. Find bounding box of the signature
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final p in points) {
      if (p != null) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    if (minX == double.infinity) return;

    double signatureWidth = maxX - minX;
    double signatureHeight = maxY - minY;
    if (signatureWidth == 0) signatureWidth = 1.0;
    if (signatureHeight == 0) signatureHeight = 1.0;

    // 2. Calculate scaling to fit in target container bounds
    const double padding = 6.0;
    final double targetWidth = size.width - (padding * 2);
    final double targetHeight = size.height - (padding * 2);

    final double scaleX = targetWidth / signatureWidth;
    final double scaleY = targetHeight / signatureHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // 3. Center the signature in the block
    final double offsetX = padding + (targetWidth - (signatureWidth * scale)) / 2;
    final double offsetY = padding + (targetHeight - (signatureHeight * scale)) / 2;

    // 4. Paint the scaled path
    Paint paint = Paint()
      ..color = const Color(0xFF1E3A8A) // Dark blue signature ink
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final p1 = Offset(
          (points[i]!.dx - minX) * scale + offsetX,
          (points[i]!.dy - minY) * scale + offsetY,
        );
        final p2 = Offset(
          (points[i + 1]!.dx - minX) * scale + offsetX,
          (points[i + 1]!.dy - minY) * scale + offsetY,
        );
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureMiniPainter oldDelegate) => true;
}
