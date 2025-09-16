import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Adaptive button that uses platform-appropriate styling
class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;
  final bool isLoading;

  const AdaptiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildCupertinoButton(context);
    }
    if (Platform.isMacOS) {
      return _buildMacOSButton(context);
    }
    return _buildMaterialButton(context);
  }

  Widget _buildCupertinoButton(BuildContext context) {
    if (isPrimary) {
      return CupertinoButton.filled(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      );
    }

    return CupertinoButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const CupertinoActivityIndicator()
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
    );
  }

  Widget _buildMaterialButton(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
        label: Text(text),
      );
    }

    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
      label: Text(text),
    );
  }

  Widget _buildMacOSButton(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      );
    }

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
    );
  }
}

/// Adaptive loading indicator
class AdaptiveLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const AdaptiveLoadingIndicator({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        radius: size != null ? size! / 2 : 10,
        color: color,
      );
    }

    if (Platform.isMacOS) {
      return CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? Theme.of(context).colorScheme.primary,
      );
    }

    return CircularProgressIndicator(strokeWidth: 2, color: color);
  }
}

/// Adaptive alert dialog
class AdaptiveAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<AdaptiveDialogAction> actions;

  const AdaptiveAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions
            .map((action) => action._buildCupertinoAction())
            .toList(),
      );
    }

    if (Platform.isMacOS) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions
            .map((action) => action._buildMaterialAction())
            .toList(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
    }

    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: actions.map((action) => action._buildMaterialAction()).toList(),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    required List<AdaptiveDialogAction> actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) =>
          AdaptiveAlertDialog(title: title, content: content, actions: actions),
    );
  }
}

/// Adaptive dialog action
class AdaptiveDialogAction {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefault;

  const AdaptiveDialogAction({
    required this.text,
    this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });

  Widget _buildCupertinoAction() {
    return CupertinoDialogAction(
      onPressed: onPressed,
      isDestructiveAction: isDestructive,
      isDefaultAction: isDefault,
      child: Text(text),
    );
  }

  Widget _buildMaterialAction() {
    if (isDestructive) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        child: Text(text),
      );
    }

    return TextButton(onPressed: onPressed, child: Text(text));
  }
}

/// Adaptive switch
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor:
            activeColor ?? CupertinoTheme.of(context).primaryColor,
      );
    }

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
    );
  }
}

/// Adaptive slider
class AdaptiveSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;

  const AdaptiveSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: activeColor ?? CupertinoTheme.of(context).primaryColor,
      );
    }

    return Slider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor,
    );
  }
}

/// Adaptive text field
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? labelText,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        suffix: suffixIcon,
        prefix: prefixIcon,
        maxLines: maxLines,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: placeholder,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

/// Adaptive app bar
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;

  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(title),
        trailing: actions != null && actions!.isNotEmpty
            ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
            : null,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor,
      );
    }

    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Size get preferredSize => Platform.isIOS
      ? const Size.fromHeight(44) // iOS navigation bar height
      : const Size.fromHeight(56); // Material app bar height
}
