import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

class PremiumTextField extends StatefulWidget {
  const PremiumTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.error,
    this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? error;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error?.trim().isNotEmpty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppText.micro.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Focus(
          onFocusChange: (focused) {
            if (_focused != focused) setState(() => _focused = focused);
          },
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.easeOut,
            constraints: BoxConstraints(
              minHeight:
                  widget.maxLines == 1 ? AppSpacing.xxxl + AppSpacing.sm : 0,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.rLg,
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : (_focused ? AppColors.purple : AppColors.border),
                width: _focused || hasError ? AppSpacing.xs / 2 : 1,
              ),
              boxShadow: _focused && !hasError
                  ? [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: .12),
                        blurRadius: AppSpacing.md,
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              style: AppText.body.copyWith(color: AppColors.text),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppText.caption.copyWith(color: AppColors.textMuted),
                prefixIcon: widget.prefixIcon == null
                    ? null
                    : Icon(widget.prefixIcon, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.error!,
            style: AppText.micro.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
