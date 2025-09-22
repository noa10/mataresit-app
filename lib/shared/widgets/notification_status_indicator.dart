import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Notification status indicator widget
/// Shows the connection status of the notification service
class NotificationStatusIndicator extends StatefulWidget {
  final bool showBadge;
  final Size size;
  final VoidCallback? onTap;

  const NotificationStatusIndicator({
    super.key,
    this.showBadge = true,
    this.size = const Size(24, 24),
    this.onTap,
  });

  @override
  State<NotificationStatusIndicator> createState() =>
      _NotificationStatusIndicatorState();
}

class _NotificationStatusIndicatorState
    extends State<NotificationStatusIndicator> {
  final NotificationService _notificationService = NotificationService();
  String _connectionStatus = 'disconnected';

  @override
  void initState() {
    super.initState();
    _initializeStatusListener();
  }

  void _initializeStatusListener() {
    _notificationService.connectionStatusStream.listen((status) {
      if (mounted) {
        setState(() => _connectionStatus = status);
      }
    });

    // Get initial status
    _connectionStatus = _notificationService.connectionStatus;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _handleTap,
      child: Tooltip(
        message: _getTooltipMessage(),
        child: SizedBox(
          width: widget.size.width,
          height: widget.size.height,
          child: Stack(
            children: [
              Icon(_getIcon(), color: _getColor(), size: widget.size.width),
              if (widget.showBadge && _shouldShowBadge())
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getBadgeColor(),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (_connectionStatus) {
      case 'connected':
        return Icons.wifi;
      case 'reconnecting':
        return Icons.wifi_off;
      default:
        return Icons.wifi_off;
    }
  }

  Color _getColor() {
    switch (_connectionStatus) {
      case 'connected':
        return Colors.green;
      case 'reconnecting':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Color _getBadgeColor() {
    switch (_connectionStatus) {
      case 'connected':
        return Colors.green;
      case 'reconnecting':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  bool _shouldShowBadge() {
    return _connectionStatus != 'connected';
  }

  String _getTooltipMessage() {
    switch (_connectionStatus) {
      case 'connected':
        return 'Notifications connected';
      case 'reconnecting':
        return 'Reconnecting to notifications...';
      default:
        return 'Notifications disconnected';
    }
  }

  void _handleTap() {
    // Navigate to notification settings
    Navigator.of(context).pushNamed('/settings/notifications');
  }
}

/// Simple notification badge widget
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? fontSize;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: badgeColor ?? Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: fontSize ?? 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Animated notification indicator
class AnimatedNotificationIndicator extends StatefulWidget {
  final bool isActive;
  final Widget child;
  final Duration animationDuration;

  const AnimatedNotificationIndicator({
    super.key,
    required this.isActive,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedNotificationIndicator> createState() =>
      _AnimatedNotificationIndicatorState();
}

class _AnimatedNotificationIndicatorState
    extends State<AnimatedNotificationIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.blue,
    ).animate(_animationController);

    if (widget.isActive) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedNotificationIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: IconTheme(
            data: IconThemeData(color: _colorAnimation.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Notification pulse indicator
class NotificationPulseIndicator extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Color pulseColor;

  const NotificationPulseIndicator({
    super.key,
    required this.child,
    this.isPulsing = false,
    this.pulseColor = Colors.blue,
  });

  @override
  State<NotificationPulseIndicator> createState() =>
      _NotificationPulseIndicatorState();
}

class _NotificationPulseIndicatorState extends State<NotificationPulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NotificationPulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isPulsing)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 40 * (1 + _pulseAnimation.value * 0.5),
                height: 40 * (1 + _pulseAnimation.value * 0.5),
                decoration: BoxDecoration(
                  color: widget.pulseColor.withValues(
                    alpha: 0.3 * (1 - _pulseAnimation.value),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}
