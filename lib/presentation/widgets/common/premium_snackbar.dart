import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

enum PremiumSnackKind { success, error, info }

void showPremiumSnack(
  BuildContext context,
  String message, {
  PremiumSnackKind kind = PremiumSnackKind.info,
}) {
  final (icon, color) = switch (kind) {
    PremiumSnackKind.success => (Icons.check_circle_rounded, AppColors.success),
    PremiumSnackKind.error => (Icons.error_rounded, AppColors.error),
    PremiumSnackKind.info => (Icons.info_rounded, AppColors.purple),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.text,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        content: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message.trim().isEmpty ? 'Please try again.' : message,
                style: AppText.caption.copyWith(color: AppColors.surface),
              ),
            ),
          ],
        ),
      ),
    );
}
