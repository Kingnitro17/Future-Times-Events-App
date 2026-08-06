import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'adaptive_wrapper.dart';

/// Platform-adaptive filled button.
/// On iOS: CupertinoButton.filled
/// On Android: FilledButton (Material 3)
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.isDestructive = false,
    this.isOutlined = false,
    this.minWidth = double.infinity,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool disabled;
  final bool isDestructive;
  final bool isOutlined;
  final double minWidth;

  VoidCallback? get _effectiveCallback =>
      (disabled || loading) ? null : onPressed;

  Color get _accentColor =>
      isDestructive ? AppTheme.errorRed : AppTheme.electricIndigo;

  @override
  Widget build(BuildContext context) {
    return AdaptiveWrapper.isIOS ? _cupertino() : _material();
  }

  Widget _cupertino() {
    final content = loading
        ? const CupertinoActivityIndicator(color: AppTheme.pureWhite)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppTheme.pureWhite),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    return SizedBox(
      width: minWidth,
      child: CupertinoButton.filled(
        onPressed: _effectiveCallback,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: content,
      ),
    );
  }

  Widget _material() {
    final content = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.pureWhite,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: minWidth,
        child: OutlinedButton(
          onPressed: _effectiveCallback,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _accentColor),
            foregroundColor: _accentColor,
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: minWidth,
      child: FilledButton(
        onPressed: _effectiveCallback,
        style: FilledButton.styleFrom(
          backgroundColor: _accentColor,
          disabledBackgroundColor: _accentColor.withOpacity(0.4),
        ),
        child: content,
      ),
    );
  }
}
