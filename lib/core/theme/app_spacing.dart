import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  static const screenPadding = 20.0;
  static const cardPadding = 16.0;
  static const sectionGap = 24.0;
  static const listItemGap = 12.0;
  static const inlineGap = 8.0;

  static const screenH = EdgeInsets.symmetric(horizontal: screenPadding);
  static const screenAll = EdgeInsets.all(screenPadding);
  static const card = EdgeInsets.all(cardPadding);
  static const cardH = EdgeInsets.symmetric(horizontal: cardPadding);
}
