import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.scrolledUnder = false,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool scrolledUnder;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.xxxl);

  @override
  Widget build(BuildContext context) => ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: scrolledUnder ? AppSpacing.sm : 0,
            sigmaY: scrolledUnder ? AppSpacing.sm : 0,
          ),
          child: AppBar(
            title: Text(title, style: AppText.h1),
            actions: actions,
            leading: leading ??
                (showBackButton
                    ? IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    : null),
            automaticallyImplyLeading: false,
            toolbarHeight: AppSpacing.xxxl,
            backgroundColor: AppColors.background.withValues(
              alpha: scrolledUnder ? .78 : 0,
            ),
            foregroundColor: AppColors.text,
            elevation: 0,
            scrolledUnderElevation: 0,
            shape: const Border(bottom: BorderSide(color: AppColors.border)),
            titleSpacing: AppSpacing.lg,
            clipBehavior: Clip.antiAlias,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            actionsPadding: const EdgeInsets.only(right: AppSpacing.sm),
            flexibleSpace: const DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ),
      );
}
