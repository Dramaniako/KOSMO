import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'contract_success_page.dart';

class SignaturePadPage extends StatefulWidget {
  const SignaturePadPage({super.key});

  @override
  State<SignaturePadPage> createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<SignaturePadPage> {
  final List<Offset?> _points = [];
  bool _hasSignature = false;

  void _clearCanvas() {
    setState(() {
      _points.clear();
      _hasSignature = false;
    });
  }

  void _submitSignature() {
    if (_points.isEmpty) return;
    
    // In a real app, we would convert this to an image and send to server.
    // Here we just navigate to success page.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ContractSuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('E-Signature', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Tanda tangani di dalam area kotak di bawah ini.',
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
            ),
            
            // Signature Canvas Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _SignatureCanvas(
                    points: _points,
                    onInteractionStart: () {
                      if (!_hasSignature) {
                        setState(() {
                          _hasSignature = true;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearCanvas,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Hapus', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !_hasSignature ? null : _submitSignature,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.border,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignatureCanvas extends StatefulWidget {
  final List<Offset?> points;
  final VoidCallback onInteractionStart;

  const _SignatureCanvas({required this.points, required this.onInteractionStart});

  @override
  State<_SignatureCanvas> createState() => _SignatureCanvasState();
}

class _SignatureCanvasState extends State<_SignatureCanvas> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => widget.onInteractionStart(),
      onPanUpdate: (DragUpdateDetails details) {
        setState(() {
          widget.points.add(details.localPosition);
        });
      },
      onPanEnd: (DragEndDetails details) {
        setState(() {
          widget.points.add(null);
        });
      },
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SignaturePainter(widget.points),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return true; // Always repaint when setState is called
  }
}
