import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// The receipt mark shared with the web workspace's Mataresit lockup.
class MataresitMark extends StatelessWidget {
  const MataresitMark({super.key, this.size = 36, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MataresitMarkPainter(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _MataresitMarkPainter extends CustomPainter {
  const _MataresitMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    // Align the centre of the ink with the wordmark, as in the web lockup.
    canvas.translate(0, -1.075);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(2.4, 7.05)
      ..lineTo(4, 5.15)
      ..lineTo(5.6, 7.05)
      ..lineTo(7.2, 5.15)
      ..lineTo(8.8, 7.05)
      ..lineTo(10.4, 5.15)
      ..lineTo(12, 7.05)
      ..lineTo(13.6, 5.15)
      ..lineTo(15.2, 7.05)
      ..lineTo(16.8, 5.15)
      ..lineTo(18.4, 7.05)
      ..lineTo(20, 5.15)
      ..lineTo(21.6, 7.05)
      ..lineTo(21.6, 21)
      ..lineTo(2.4, 21)
      ..close()
      ..addRect(const Rect.fromLTRB(5.2, 9.4, 16.8, 10.9))
      ..addRect(const Rect.fromLTRB(5.2, 12.7, 20.2, 14.2))
      ..addRect(const Rect.fromLTRB(5.2, 16, 13.6, 17.5))
      ..addRect(const Rect.fromLTRB(5.2, 18.8, 18.4, 20.3));
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MataresitMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class MataresitLogo extends StatelessWidget {
  final double size;
  final bool showTitle;
  final TextStyle? titleStyle;
  final double spacing;
  final bool showContainer;
  final Color? containerColor;
  final double? borderRadius;

  const MataresitLogo({
    super.key,
    this.size = 80,
    this.showTitle = false,
    this.titleStyle,
    this.spacing = AppConstants.defaultPadding,
    this.showContainer = false,
    this.containerColor,
    this.borderRadius,
  });

  factory MataresitLogo.login({double size = 100, bool showTitle = true}) =>
      MataresitLogo(size: size, showTitle: showTitle);

  factory MataresitLogo.appBar({double size = 32, bool showTitle = true}) =>
      MataresitLogo(
        size: size,
        showTitle: showTitle,
        spacing: AppConstants.smallPadding,
      );

  factory MataresitLogo.splash({double size = 120, bool showTitle = true}) =>
      MataresitLogo(
        size: size,
        showTitle: showTitle,
        showContainer: true,
        spacing: AppConstants.largePadding,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget mark = MataresitMark(size: size);
    if (showContainer) {
      mark = Container(
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          color: containerColor ?? theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(borderRadius ?? 10),
        ),
        child: mark,
      );
    }
    if (!showTitle) return mark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(height: spacing),
        Text(
          AppConstants.appName,
          style:
              titleStyle ??
              theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class MataresitLogoHorizontal extends StatelessWidget {
  final double size;
  final TextStyle? titleStyle;
  final double spacing;

  const MataresitLogoHorizontal({
    super.key,
    this.size = 32,
    this.titleStyle,
    this.spacing = AppConstants.smallPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MataresitMark(size: size),
        SizedBox(width: spacing),
        Text(
          AppConstants.appName,
          style:
              titleStyle ??
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
