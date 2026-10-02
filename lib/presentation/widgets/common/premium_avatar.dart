import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class PremiumAvatar extends StatelessWidget {
  const PremiumAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 40,
    this.ringColor,
  });

  final String? imageUrl;
  final String? initials;
  final double size;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final content = url == null || url.isEmpty
        ? _fallback()
        : ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            ),
          );
    return Container(
      width: size,
      height: size,
      padding: ringColor == null ? EdgeInsets.zero : const EdgeInsets.all(2),
      decoration: ringColor == null
          ? null
          : BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor!, width: 2),
            ),
      child: ClipOval(child: content),
    );
  }

  Widget _fallback() => ColoredBox(
        color: AppColors.purpleLight,
        child: Center(
          child: Text(
            _normalizedInitials,
            style: TextStyle(
              color: AppColors.surface,
              fontSize: size * .34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  String get _normalizedInitials {
    final value = initials?.trim();
    if (value == null || value.isEmpty) return '?';
    final letters = value.characters.take(2).toString();
    return letters.toUpperCase();
  }
}
