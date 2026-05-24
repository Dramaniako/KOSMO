import 'package:flutter/material.dart';

enum OverlayShape { rectangle, oval }

class ScannerOverlay extends StatelessWidget {
  final OverlayShape shape;
  final Color borderColor;
  final double strokeWidth;
  final Color? laserColor;
  final double? laserProgress;
  final double? progress;
  final Color? progressColor;

  const ScannerOverlay({
    super.key,
    required this.shape,
    this.borderColor = Colors.white,
    this.strokeWidth = 3.0,
    this.laserColor,
    this.laserProgress,
    this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(
        shape: shape,
        borderColor: borderColor,
        strokeWidth: strokeWidth,
        laserColor: laserColor,
        laserProgress: laserProgress,
        progress: progress,
        progressColor: progressColor,
      ),
      child: Container(),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final OverlayShape shape;
  final Color borderColor;
  final double strokeWidth;
  final Color? laserColor;
  final double? laserProgress;
  final double? progress;
  final Color? progressColor;

  _ScannerOverlayPainter({
    required this.shape,
    required this.borderColor,
    required this.strokeWidth,
    this.laserColor,
    this.laserProgress,
    this.progress,
    this.progressColor,
  });

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
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        borderPaint,
      );

      // Draw horizontal laser scanning line
      if (laserColor != null && laserProgress != null) {
        final laserY = rect.top + rect.height * laserProgress!;
        final laserPaint = Paint()
          ..color = laserColor!
          ..strokeWidth = 2.0;
        canvas.drawLine(
          Offset(rect.left, laserY),
          Offset(rect.right, laserY),
          laserPaint,
        );

        // Draw laser glow/shadow
        final glowPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              laserColor!.withValues(alpha: 0.3),
              laserColor!.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTRB(rect.left, laserY - 12, rect.right, laserY))
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTRB(rect.left, laserY - 12, rect.right, laserY),
          glowPaint,
        );
      }
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
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawOval(rect, borderPaint);

      // Draw progress arc around the oval
      if (progress != null) {
        final progressPaint = Paint()
          ..color = progressColor ?? Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 2.0
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          rect,
          -3.14159 / 2, // Start at the top (-90 degrees)
          2 * 3.14159 * progress!, // Sweep angle
          false,
          progressPaint,
        );
      }
    }

    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.laserColor != laserColor ||
        oldDelegate.laserProgress != laserProgress ||
        oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
