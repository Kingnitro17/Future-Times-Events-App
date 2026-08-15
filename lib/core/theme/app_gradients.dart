import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppGradients {
  static const brand = LinearGradient(
    colors: [AppColors.pink, AppColors.purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
