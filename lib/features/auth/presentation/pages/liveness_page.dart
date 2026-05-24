import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/scanner_overlay.dart';
import '../providers/auth_provider.dart';

class LivenessPage extends ConsumerStatefulWidget {
  const LivenessPage({super.key});

  @override
  ConsumerState<LivenessPage> createState() => _LivenessPageState();
}

class _LivenessPageState extends ConsumerState<LivenessPage>
    with TickerProviderStateMixin {
  int _phase = 0; // 0 = Align Face, 1 = Blink, 2 = Smile, 3 = Done
  double _alignmentProgress = 0.0;
  double _smileProgress = 0.0;
  bool _blinkState = false; // true = closed eye, false = open eye
  Timer? _timer;

  late AnimationController _pulseController;

  final List<String> _instructions = [
    'Posisikan wajah Anda di dalam oval.',
    'Berkedip sekarang.',
    'Tersenyum lebar.',
    'Verifikasi Wajah Selesai!',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startFaceAlignment();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startFaceAlignment() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (_alignmentProgress < 1.0) {
        setState(() {
          _alignmentProgress += 0.025; // 2 seconds total
        });
      } else {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _startBlinkDetection() {
    // 1. Wait 1 second of normal face, then trigger blink
    _timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _blinkState = true; // Simulating closed eyes
      });

      // 2. Keep eyes closed for 300ms, then open and advance
      _timer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _blinkState = false;
        });
        _nextPhase();
      });
    });
  }

  void _startSmileDetection() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (_smileProgress < 1.0) {
        setState(() {
          _smileProgress += 0.025; // 2 seconds total
        });
      } else {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    if (!mounted) return;
    if (_phase < 3) {
      setState(() {
        _phase++;
      });

      if (_phase == 1) {
        _startBlinkDetection();
      } else if (_phase == 2) {
        _startSmileDetection();
      } else if (_phase == 3) {
        _showCompletionDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate pulse for alignment border if active
    final pulseColor = Color.lerp(
      Colors.white38,
      Colors.white,
      _pulseController.value,
    )!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Verifikasi Wajah',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Mock Camera Preview for Selfie
          Container(
            color: Colors.grey.shade900,
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Icon(
                Icons.face_rounded,
                color: Colors.white24,
                size: 100,
              ),
            ),
          ),

          // Custom Scanner Overlay
          ScannerOverlay(
            shape: OverlayShape.oval,
            borderColor: _phase == 0 ? pulseColor : AppColors.secondary,
            progress: _phase == 0 ? _alignmentProgress : 1.0,
            progressColor: AppColors.secondary,
          ),

          // Liveness Simulation Indicators and Instructions
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Prompt Header
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, left: 24, right: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _phase == 3 ? AppColors.secondary : Colors.white24,
                      ),
                    ),
                    child: Text(
                      _instructions[_phase],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _phase == 3 ? AppColors.secondary : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Bottom Status Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: _buildStatusCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Langkah Verifikasi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Steps list
          _buildStepRow(
            label: 'Sejajarkan Wajah',
            isActive: _phase == 0,
            isCompleted: _phase > 0,
            progress: _phase == 0 ? _alignmentProgress : null,
          ),
          const SizedBox(height: 12),
          _buildStepRow(
            label: 'Kedipkan Mata',
            isActive: _phase == 1,
            isCompleted: _phase > 1,
            trailingWidget: _phase == 1
                ? Icon(
                    _blinkState ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.amber,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          _buildStepRow(
            label: 'Senyuman Lebar',
            isActive: _phase == 2,
            isCompleted: _phase > 2,
            trailingWidget: _phase == 2
                ? Text(
                    '${(_smileProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          // Smile meter bar
          if (_phase == 2) ...[
            const SizedBox(height: 16),
            const Text(
              'Smile Meter',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _smileProgress,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(Colors.orange, AppColors.secondary, _smileProgress)!,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String label,
    required bool isActive,
    required bool isCompleted,
    double? progress,
    Widget? trailingWidget,
  }) {
    IconData icon = Icons.circle_outlined;
    Color iconColor = Colors.white24;

    if (isCompleted) {
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.secondary;
    } else if (isActive) {
      icon = Icons.radio_button_checked_rounded;
      iconColor = AppColors.primary;
    }

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isCompleted
                  ? Colors.white70
                  : isActive
                      ? Colors.white
                      : Colors.white30,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (progress != null && isActive) ...[
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ] else if (trailingWidget != null) ...[
          trailingWidget
        ],
      ],
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: const Icon(
          Icons.verified_rounded,
          color: AppColors.secondary,
          size: 64,
        ),
        content: const Text(
          'Verifikasi KYC Berhasil!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Set verified state in Riverpod AuthProvider and local storage
                ref.read(authProvider.notifier).verifyUser();
                // Pop back to home
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Selesai',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
