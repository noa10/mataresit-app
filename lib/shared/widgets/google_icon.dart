import 'package:flutter/material.dart';

/// Custom Google icon widget with proper branding colors
class GoogleIcon extends StatelessWidget {
  final double size;
  
  const GoogleIcon({
    super.key,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

/// Custom painter for Google's "G" logo
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Google Blue (#4285F4)
    paint.color = const Color(0xFF4285F4);
    
    // Draw the blue section (top-right quarter and right half)
    final bluePath = Path();
    bluePath.moveTo(center.dx, center.dy - radius);
    bluePath.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // -90 degrees (top)
      1.57,  // 90 degrees (to right)
      false,
    );
    bluePath.lineTo(center.dx + radius * 0.6, center.dy);
    bluePath.lineTo(center.dx + radius * 0.6, center.dy - radius * 0.3);
    bluePath.lineTo(center.dx, center.dy - radius * 0.3);
    bluePath.close();
    canvas.drawPath(bluePath, paint);

    // Google Red (#EA4335)
    paint.color = const Color(0xFFEA4335);
    
    // Draw the red section (top-left quarter)
    final redPath = Path();
    redPath.moveTo(center.dx, center.dy - radius);
    redPath.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // -90 degrees (top)
      -1.57, // -90 degrees (to left)
      false,
    );
    redPath.lineTo(center.dx, center.dy);
    redPath.close();
    canvas.drawPath(redPath, paint);

    // Google Yellow (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    
    // Draw the yellow section (bottom-left quarter)
    final yellowPath = Path();
    yellowPath.moveTo(center.dx - radius, center.dy);
    yellowPath.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      3.14, // 180 degrees (left)
      1.57, // 90 degrees (to bottom)
      false,
    );
    yellowPath.lineTo(center.dx, center.dy);
    yellowPath.close();
    canvas.drawPath(yellowPath, paint);

    // Google Green (#34A853)
    paint.color = const Color(0xFF34A853);
    
    // Draw the green section (bottom-right quarter)
    final greenPath = Path();
    greenPath.moveTo(center.dx, center.dy + radius);
    greenPath.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      1.57, // 90 degrees (bottom)
      1.57, // 90 degrees (to right)
      false,
    );
    greenPath.lineTo(center.dx, center.dy);
    greenPath.close();
    canvas.drawPath(greenPath, paint);

    // Draw white center circle to create the "G" shape
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.35, paint);

    // Draw the opening for the "G"
    paint.color = const Color(0xFF4285F4);
    final openingRect = Rect.fromLTWH(
      center.dx,
      center.dy - radius * 0.15,
      radius * 0.6,
      radius * 0.3,
    );
    canvas.drawRect(openingRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
