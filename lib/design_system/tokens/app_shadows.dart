import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  /// Inputs and buttons on the warm background.
  static const List<BoxShadow> field = [
    BoxShadow(color: AppColors.shadow, offset: Offset(0, 2), blurRadius: 4),
  ];

  /// Cards on shopping screens.
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadowSoft, offset: Offset(0, 2), blurRadius: 10, spreadRadius: -2),
    BoxShadow(color: AppColors.shadowSoft, offset: Offset(0, 8), blurRadius: 24, spreadRadius: -4),
  ];

  /// Floating bars (basket, bottom navigation).
  static const List<BoxShadow> floating = [
    BoxShadow(color: AppColors.shadow, offset: Offset(0, 6), blurRadius: 18, spreadRadius: -4),
  ];

  static const List<BoxShadow> topBar = [
    BoxShadow(color: AppColors.shadowSoft, offset: Offset(0, -4), blurRadius: 20, spreadRadius: -2),
  ];
}
