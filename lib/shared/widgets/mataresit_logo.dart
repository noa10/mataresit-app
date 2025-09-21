import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// A reusable Mataresit logo widget that can be used across the app
/// Supports different sizes and contexts (login, dashboard, etc.)
class MataresitLogo extends StatelessWidget {
  /// The size of the logo
  final double size;
  
  /// Whether to show the app title below the logo
  final bool showTitle;
  
  /// The title text style
  final TextStyle? titleStyle;
  
  /// The spacing between logo and title
  final double spacing;
  
  /// Whether to show the logo in a container with background
  final bool showContainer;
  
  /// The container background color
  final Color? containerColor;
  
  /// The container border radius
  final double? borderRadius;

  const MataresitLogo({
    super.key,
    this.size = 80.0,
    this.showTitle = false,
    this.titleStyle,
    this.spacing = AppConstants.defaultPadding,
    this.showContainer = false,
    this.containerColor,
    this.borderRadius,
  });

  /// Factory constructor for login screen usage
  factory MataresitLogo.login({
    double size = 100.0,
    bool showTitle = true,
  }) {
    return MataresitLogo(
      size: size,
      showTitle: showTitle,
      showContainer: false,
      spacing: AppConstants.defaultPadding,
    );
  }

  /// Factory constructor for dashboard/app bar usage
  factory MataresitLogo.appBar({
    double size = 32.0,
    bool showTitle = true,
  }) {
    return MataresitLogo(
      size: size,
      showTitle: showTitle,
      showContainer: false,
      spacing: AppConstants.smallPadding,
    );
  }

  /// Factory constructor for splash screen usage
  factory MataresitLogo.splash({
    double size = 120.0,
    bool showTitle = true,
  }) {
    return MataresitLogo(
      size: size,
      showTitle: showTitle,
      showContainer: true,
      spacing: AppConstants.largePadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget logoImage = Image.asset(
      'assets/mataresit-icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image fails to load
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppConstants.largeBorderRadius,
            ),
          ),
          child: Icon(
            Icons.receipt_long,
            size: size * 0.5,
            color: theme.primaryColor,
          ),
        );
      },
    );

    // Wrap in container if requested
    if (showContainer) {
      logoImage = Container(
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          color: containerColor ?? 
                 theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppConstants.largeBorderRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: logoImage,
      );
    }

    // Return just logo if no title
    if (!showTitle) {
      return logoImage;
    }

    // Return logo with title
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoImage,
        SizedBox(height: spacing),
        Text(
          AppConstants.appName,
          style: titleStyle ??
                 theme.textTheme.headlineMedium?.copyWith(
                   fontWeight: FontWeight.bold,
                   color: theme.colorScheme.onSurface,
                 ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A horizontal variant of the Mataresit logo with title beside the logo
class MataresitLogoHorizontal extends StatelessWidget {
  /// The size of the logo
  final double size;
  
  /// The title text style
  final TextStyle? titleStyle;
  
  /// The spacing between logo and title
  final double spacing;

  const MataresitLogoHorizontal({
    super.key,
    this.size = 32.0,
    this.titleStyle,
    this.spacing = AppConstants.smallPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/mataresit-icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image fails to load
            return Icon(
              Icons.receipt_long,
              size: size,
              color: theme.primaryColor,
            );
          },
        ),
        SizedBox(width: spacing),
        Text(
          AppConstants.appName,
          style: titleStyle ??
                 theme.textTheme.titleLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   color: theme.colorScheme.onSurface,
                 ),
        ),
      ],
    );
  }
}
