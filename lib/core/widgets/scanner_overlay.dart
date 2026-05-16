import 'package:flutter/material.dart';

enum OverlayShape { rectangle, oval }

class ScannerOverlay extends StatelessWidget {
  final OverlayShape shape;

  const ScannerOverlay({super.key, required this.shape});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(shape: shape),
      child: Container(),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final OverlayShape shape;

  _ScannerOverlayPainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    Path cutoutPath;
    if (shape == OverlayShape.rectangle) {
      // KTP Ratio is around 85.60 mm x 53.98 mm (~1.58 ratio)
      final width = size.width * 0.85;
      final height = width / 1.58;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: width,
        height: height,
      );
      cutoutPath = Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)));

      // Draw border box
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        borderPaint,
      );
    } else {
      // Oval for Face
      final width = size.width * 0.7;
      final height = width * 1.3;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2.2),
        width: width,
        height: height,
      );
      cutoutPath = Path()..addOval(rect);

      // Draw border oval
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawOval(rect, borderPaint);
    }

    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
