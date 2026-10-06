import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class CategoryColors {
  static Color forCategory(String? category) {
    if (category == null) return AppColors.categoryOther;
    final key = category.toLowerCase().trim();
    if (key.contains('music') || key.contains('concert')) {
      return AppColors.categoryMusic;
    }
    if (key.contains('sport') || key.contains('game')) {
      return AppColors.categorySports;
    }
    if (key.contains('food') || key.contains('drink')) {
      return AppColors.categoryFood;
    }
    if (key.contains('night') || key.contains('club')) {
      return AppColors.categoryNightlife;
    }
    if (key.contains('expo') ||
        key.contains('business') ||
        key.contains('conference')) {
      return AppColors.categoryExpos;
    }
    if (key.contains('art') || key.contains('culture')) {
      return AppColors.categoryArts;
    }
    return AppColors.categoryOther;
  }
}
