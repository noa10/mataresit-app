import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';

/// An enhanced user avatar widget that can display profile images from various sources
/// with proper caching, error handling, and fallback to initials
class EnhancedUserAvatar extends StatelessWidget {
  /// The user model containing avatar information
  final UserModel? user;

  /// The size of the avatar (radius)
  final double radius;

  /// Custom background color for the avatar
  final Color? backgroundColor;

  /// Custom text color for initials
  final Color? textColor;

  /// Custom text style for initials
  final TextStyle? textStyle;

  /// Whether to show a border around the avatar
  final bool showBorder;

  /// Border color
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Custom fallback text (overrides user initials)
  final String? fallbackText;

  /// Custom fallback icon
  final IconData? fallbackIcon;

  /// Whether to show online indicator
  final bool showOnlineIndicator;

  /// Online status
  final bool isOnline;

  const EnhancedUserAvatar({
    super.key,
    this.user,
    this.radius = 20.0,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.fallbackText,
    this.fallbackIcon,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  /// Factory constructor for small avatars (e.g., in lists)
  factory EnhancedUserAvatar.small({
    UserModel? user,
    bool showOnlineIndicator = false,
    bool isOnline = false,
  }) {
    return EnhancedUserAvatar(
      user: user,
      radius: 16.0,
      showOnlineIndicator: showOnlineIndicator,
      isOnline: isOnline,
    );
  }

  /// Factory constructor for medium avatars (e.g., in cards)
  factory EnhancedUserAvatar.medium({
    UserModel? user,
    bool showBorder = false,
    bool showOnlineIndicator = false,
    bool isOnline = false,
  }) {
    return EnhancedUserAvatar(
      user: user,
      radius: 24.0,
      showBorder: showBorder,
      showOnlineIndicator: showOnlineIndicator,
      isOnline: isOnline,
    );
  }

  /// Factory constructor for large avatars (e.g., in profile screens)
  factory EnhancedUserAvatar.large({
    UserModel? user,
    bool showBorder = true,
    bool showOnlineIndicator = false,
    bool isOnline = false,
  }) {
    return EnhancedUserAvatar(
      user: user,
      radius: 40.0,
      showBorder: showBorder,
      borderWidth: 3.0,
      showOnlineIndicator: showOnlineIndicator,
      isOnline: isOnline,
    );
  }

  /// Get the best available avatar URL
  String? get _avatarUrl {
    if (user == null) return null;

    // Priority: custom avatar_url > google_avatar_url
    if (user!.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      return user!.avatarUrl;
    }

    if (user!.googleAvatarUrl != null && user!.googleAvatarUrl!.isNotEmpty) {
      return user!.googleAvatarUrl;
    }

    return null;
  }

  /// Get user initials for fallback
  String get _userInitials {
    if (fallbackText != null) return fallbackText!;
    if (user == null) return 'U';

    final firstName = user!.firstName?.trim() ?? '';
    final lastName = user!.lastName?.trim() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    } else if (user!.email != null && user!.email!.isNotEmpty) {
      return user!.email![0].toUpperCase();
    }

    return 'U';
  }

  /// Build the fallback avatar with initials or icon
  Widget _buildFallbackAvatar(
    BuildContext context,
    Color bgColor,
    Color fgColor,
  ) {
    if (fallbackIcon != null) {
      return Icon(fallbackIcon, size: radius * 0.8, color: fgColor);
    }

    return Text(
      _userInitials,
      style:
          textStyle ??
          TextStyle(
            color: fgColor,
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// Build the online indicator
  Widget _buildOnlineIndicator() {
    if (!showOnlineIndicator) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: radius * 0.4,
        height: radius * 0.4,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor;
    final fgColor = textColor ?? theme.colorScheme.onPrimary;
    final bColor = borderColor ?? theme.colorScheme.outline;

    Widget avatar;
    final avatarUrl = _avatarUrl;

    if (avatarUrl != null) {
      // Try to load network image with caching
      avatar = CachedNetworkImage(
        imageUrl: avatarUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
          backgroundColor: bgColor,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: bgColor.withValues(alpha: 0.3),
          child: SizedBox(
            width: radius * 0.6,
            height: radius * 0.6,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          child: _buildFallbackAvatar(context, bgColor, fgColor),
        ),
      );
    } else {
      // Use fallback avatar with initials or icon
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: _buildFallbackAvatar(context, bgColor, fgColor),
      );
    }

    // Add border if requested
    if (showBorder) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: bColor, width: borderWidth),
        ),
        child: avatar,
      );
    }

    // Add online indicator if requested
    if (showOnlineIndicator) {
      avatar = Stack(children: [avatar, _buildOnlineIndicator()]);
    }

    return avatar;
  }
}

/// A specialized avatar widget for dashboard welcome sections
class WelcomeAvatar extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onTap;

  const WelcomeAvatar({super.key, this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatar = EnhancedUserAvatar.large(user: user, showBorder: true);

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
