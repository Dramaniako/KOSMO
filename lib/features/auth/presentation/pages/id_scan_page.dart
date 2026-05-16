import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/scanner_overlay.dart';
import 'liveness_page.dart';

class IdScanPage extends StatelessWidget {
  const IdScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for scanner
      appBar: AppBar(
        title: const Text('Foto KTP', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Mock Camera Preview
          Container(
            color: Colors.grey.shade900,
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Text(
                'Camera Preview\n(Mock)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 18),
              ),
            ),
          ),
          
          // Scanner Overlay Frame
          const ScannerOverlay(shape: OverlayShape.rectangle),
          
          // Instructions
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 40.0, left: 24, right: 24),
                  child: Text(
                    'Posisikan KTP Anda tepat di dalam bingkai.\nPastikan tulisan terbaca jelas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
                
                // Capture Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: GestureDetector(
                    onTap: () {
                      // Simulating capture and proceed
                      _showSuccessDialog(context);
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 64),
        content: const Text(
          'KTP berhasil dipindai!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LivenessPage()),
                );
              },
              child: const Text('Lanjut', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
