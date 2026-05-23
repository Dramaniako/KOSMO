import 'package:flutter/material.dart';
import '../../../../core/services/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/scanner_overlay.dart';

class LivenessPage extends StatefulWidget {
  const LivenessPage({super.key});

  @override
  State<LivenessPage> createState() => _LivenessPageState();
}

class _LivenessPageState extends State<LivenessPage> {
  int _step = 0;
  final List<String> _instructions = [
    'Posisikan wajah Anda di dalam area oval.',
    'Berkedip sekarang.',
    'Tersenyum sebentar.',
    'Verifikasi Selesai!',
  ];

  void _nextStep() {
    if (_step < _instructions.length - 1) {
      setState(() {
        _step++;
      });

      if (_step == _instructions.length - 1) {
        // Mock finishing the liveness detection after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          _showCompletionDialog();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Text(
                'Front Camera Preview\n(Mock)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          ),

          // Scanner Overlay Frame
          const ScannerOverlay(shape: OverlayShape.oval),

          // Instructions
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Container(
                        key: ValueKey<int>(_step),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _step == _instructions.length - 1
                                ? AppColors.secondary
                                : Colors.white54,
                          ),
                        ),
                        child: Text(
                          _instructions[_step],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _step == _instructions.length - 1
                                ? AppColors.secondary
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Next Step Button (Simulation)
                if (_step < _instructions.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 32,
                        ),
                      ),
                      child: const Text(
                        'Simulasikan Lanjut',
                        style: TextStyle(color: Colors.white),
                        textScaler: TextScaler.linear(1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(
          Icons.verified_rounded,
          color: AppColors.secondary,
          size: 64,
        ),
        content: const Text(
          'Verifikasi KYC Berhasil!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                // Set verified state
                AppState().isVerified = true;
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
