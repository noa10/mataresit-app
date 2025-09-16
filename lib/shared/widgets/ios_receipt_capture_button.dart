import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';
import '../../core/guards/subscription_guard.dart';

/// iOS-specific receipt capture button that integrates with navigation bar
class IOSReceiptCaptureButton extends ConsumerWidget {
  final bool isLarge;
  final String? tooltip;

  const IOSReceiptCaptureButton({
    super.key,
    this.isLarge = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isIOS) {
      // Fallback to Material design for non-iOS platforms
      return FloatingActionButton(
        onPressed: () => _handleCapture(context, ref),
        tooltip: tooltip ?? 'Capture Receipt',
        child: const Icon(Icons.camera_alt),
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _handleCapture(context, ref),
      child: Container(
        width: isLarge ? 56 : 44,
        height: isLarge ? 56 : 44,
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(isLarge ? 28 : 22),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          CupertinoIcons.camera_fill,
          color: CupertinoColors.white,
          size: isLarge ? 28 : 24,
        ),
      ),
    );
  }

  Future<void> _handleCapture(BuildContext context, WidgetRef ref) async {
    // Add iOS-specific haptic feedback
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    }

    // Check subscription limits before allowing receipt capture
    final canUpload = await SubscriptionGuard.showReceiptLimitDialogIfNeeded(
      context,
      ref,
      additionalReceipts: 1,
    );

    if (canUpload && context.mounted) {
      context.push(AppRoutes.receiptCapture);
    }
  }
}

/// iOS-style navigation bar with receipt capture button
class IOSNavigationBarWithCapture extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showCaptureButton;

  const IOSNavigationBarWithCapture({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showCaptureButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      // Fallback to Material AppBar for non-iOS platforms
      return AppBar(
        title: Text(title),
        actions: _buildActions(),
        leading: leading,
      );
    }

    return CupertinoNavigationBar(
      middle: Text(title),
      trailing: _buildTrailing(),
      leading: leading,
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
    );
  }

  Widget? _buildTrailing() {
    final List<Widget> trailingWidgets = [];

    if (showCaptureButton) {
      trailingWidgets.add(const IOSReceiptCaptureButton());
    }

    if (actions != null) {
      trailingWidgets.addAll(actions!);
    }

    if (trailingWidgets.isEmpty) return null;

    if (trailingWidgets.length == 1) {
      return trailingWidgets.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: trailingWidgets
          .map(
            (widget) =>
                Padding(padding: const EdgeInsets.only(left: 8), child: widget),
          )
          .toList(),
    );
  }

  List<Widget>? _buildActions() {
    final List<Widget> actionWidgets = [];

    if (showCaptureButton) {
      actionWidgets.add(const IOSReceiptCaptureButton());
    }

    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return actionWidgets.isEmpty ? null : actionWidgets;
  }

  @override
  Size get preferredSize => Platform.isIOS
      ? const Size.fromHeight(44) // iOS navigation bar height
      : const Size.fromHeight(56); // Material app bar height
}

/// iOS-style section header
class IOSSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const IOSSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      // Material design fallback
      return Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
    }

    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              letterSpacing: 0.5,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// iOS-style list tile
class IOSListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final EdgeInsetsGeometry? contentPadding;

  const IOSListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      // Material design fallback
      return ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing:
            trailing ?? (showChevron ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
        contentPadding: contentPadding,
      );
    }

    return CupertinoListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing:
          trailing ??
          (showChevron ? const Icon(CupertinoIcons.chevron_right) : null),
      onTap: onTap,
      padding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

/// iOS-style grouped section
class IOSGroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const IOSGroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      // Material design fallback
      return Container(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    header!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ...children,
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    footer!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      child: CupertinoListSection.insetGrouped(
        header: header != null ? Text(header!) : null,
        footer: footer != null ? Text(footer!) : null,
        children: children,
      ),
    );
  }
}
