import 'package:flutter/material.dart';

class AppBarWithActions extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const AppBarWithActions({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: subtitle != null
          ? Column(
              crossAxisAlignment: centerTitle 
                  ? CrossAxisAlignment.center 
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
                Text(
                  subtitle!,
                  style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          : Text(title),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
