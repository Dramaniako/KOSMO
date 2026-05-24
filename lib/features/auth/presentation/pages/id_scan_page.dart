import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/scanner_overlay.dart';
import '../../../../../core/providers/shared_preferences_provider.dart';
import '../providers/auth_provider.dart';
import 'liveness_page.dart';

enum IdScanState { aligning, countdown, scanning, processing, review }

class IdScanPage extends ConsumerStatefulWidget {
  const IdScanPage({super.key});

  @override
  ConsumerState<IdScanPage> createState() => _IdScanPageState();
}

class _IdScanPageState extends ConsumerState<IdScanPage>
    with TickerProviderStateMixin {
  IdScanState _currentState = IdScanState.aligning;
  int _countdown = 3;
  int _ocrIndex = 0;
  Timer? _stateTimer;

  late AnimationController _laserController;
  late AnimationController _flashController;

  final List<String> _ocrSteps = [
    'Menyeimbangkan pencahayaan...',
    'Mengekstrak nomor NIK...',
    'Mendeteksi data biometrik...',
    'Sinkronisasi dengan Dukcapil...',
    'Selesai!',
  ];

  // OCR Extracted Data
  late String _extractedNik;
  late String _extractedName;
  final String _extractedAddress =
      'JL. SETIABUDI TENGAH NO. 12, RT 005/RW 001, JAKARTA SELATAN';

  @override
  void initState() {
    super.initState();

    _extractedNik = '317409${_generateRandomDigits(10)}';

    // Setup animations
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _startAlignmentTimer();
  }

  String _generateRandomDigits(int length) {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.substring(random.length - length);
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    _laserController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _startAlignmentTimer() {
    _stateTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentState = IdScanState.countdown;
        });
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    _stateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _triggerCapture();
      }
    });
  }

  void _triggerCapture() {
    // 1. Shutter Flash
    _flashController.forward(from: 0.0).then((_) {
      _flashController.reverse();
    });

    // 2. Start laser scanning animation
    setState(() {
      _currentState = IdScanState.scanning;
    });
    _laserController.repeat(reverse: true);

    // 3. Keep scanning for 2.5 seconds, then transition to OCR processing
    _stateTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _laserController.stop();
      setState(() {
        _currentState = IdScanState.processing;
      });
      _startOcrSimulation();
    });
  }

  void _startOcrSimulation() {
    _stateTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) return;
      if (_ocrIndex < _ocrSteps.length - 1) {
        setState(() {
          _ocrIndex++;
        });
      } else {
        timer.cancel();
        // Fetch original user name from auth state to make it look realistic
        final userName = ref.read(authProvider).user?.name ?? 'Budi Santoso';
        setState(() {
          _extractedName = userName.toUpperCase();
          _currentState = IdScanState.review;
        });
      }
    });
  }

  void _resetScan() {
    _stateTimer?.cancel();
    _laserController.stop();
    setState(() {
      _currentState = IdScanState.aligning;
      _countdown = 3;
      _ocrIndex = 0;
    });
    _startAlignmentTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _currentState == IdScanState.review
              ? 'Verifikasi Data KTP'
              : 'Foto KTP',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          if (_currentState != IdScanState.review) ...[
            // Mock Camera Preview
            Container(
              color: Colors.grey.shade900,
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white24,
                  size: 80,
                ),
              ),
            ),

            // Scanner Overlay
            AnimatedBuilder(
              animation: _laserController,
              builder: (context, child) {
                return ScannerOverlay(
                  shape: OverlayShape.rectangle,
                  borderColor: _currentState == IdScanState.countdown
                      ? AppColors.secondary
                      : Colors.white,
                  laserColor: _currentState == IdScanState.scanning
                      ? AppColors.secondary
                      : null,
                  laserProgress: _currentState == IdScanState.scanning
                      ? _laserController.value
                      : null,
                );
              },
            ),

            // White Flash Overlay
            FadeTransition(
              opacity: _flashController,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // Instructional overlays
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 40.0,
                      left: 24,
                      right: 24,
                    ),
                    child: _buildInstructionText(),
                  ),

                  // Capture Control/Indicators
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0),
                    child: _buildBottomIndicator(),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Review state full-screen
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pastikan data hasil pemindaian OCR sesuai dengan KTP fisik Anda.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Holographic ID Card Mockup
                    _buildIdCardMockup(),

                    const SizedBox(height: 32),

                    // Input Form Fields (Verified Details)
                    _buildReviewForm(),

                    const SizedBox(height: 40),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetScan,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Foto Ulang'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final prefs = ref.read(sharedPreferencesProvider);
                              await prefs.setString('ktp_nik', _extractedNik);
                              await prefs.setString('ktp_address', _extractedAddress);

                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LivenessPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Data Benar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionText() {
    String text = '';
    Color textColor = Colors.white;

    switch (_currentState) {
      case IdScanState.aligning:
        text =
            'Posisikan KTP Anda tepat di dalam bingkai.\nPastikan tulisan terbaca jelas.';
        break;
      case IdScanState.countdown:
        text = 'KTP Terdeteksi! Mohon jangan bergerak.';
        textColor = AppColors.secondary;
        break;
      case IdScanState.scanning:
        text = 'Sedang memindai KTP...';
        textColor = AppColors.secondary;
        break;
      case IdScanState.processing:
        text = 'Memproses Gambar KTP...';
        break;
      default:
        break;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
      ),
    );
  }

  Widget _buildBottomIndicator() {
    if (_currentState == IdScanState.aligning) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Mencari KTP...',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else if (_currentState == IdScanState.countdown) {
      return Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.secondary, width: 3),
          ),
          child: Center(
            child: Text(
              '$_countdown',
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    } else if (_currentState == IdScanState.scanning) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.secondary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary),
              SizedBox(width: 12),
              Text(
                'Scanning...',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Processing loader
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _ocrSteps[_ocrIndex],
                  key: ValueKey<int>(_ocrIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildIdCardMockup() {
    return Container(
      width: double.infinity,
      height: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withValues(alpha: 0.95),
            const Color(0xFF0F172A).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Holographic patterns mock
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.blur_circular_rounded,
              size: 140,
              color: Colors.tealAccent.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: 20,
            bottom: -30,
            child: Container(
              width: 150,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Card contents
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'REPUBLIK INDONESIA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'KTP-EL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Details
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NIK',
                          style: TextStyle(color: Colors.white30, fontSize: 8),
                        ),
                        Text(
                          _extractedNik,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Nama',
                          style: TextStyle(color: Colors.white30, fontSize: 8),
                        ),
                        Text(
                          _extractedName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Alamat',
                          style: TextStyle(color: Colors.white30, fontSize: 8),
                        ),
                        Text(
                          _extractedAddress,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User Photo Mock
                  Container(
                    width: 75,
                    height: 95,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Hasil Pemindaian',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildReviewField('NIK KTP', _extractedNik),
        const SizedBox(height: 16),
        _buildReviewField('Nama Lengkap', _extractedName),
        const SizedBox(height: 16),
        _buildReviewField('Alamat', _extractedAddress, maxLines: 2),
      ],
    );
  }

  Widget _buildReviewField(String label, String value, {int maxLines = 1}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
