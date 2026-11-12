import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

enum AppTextVariant { header2, header3, subhead, title, callout, body, bodyMedium, caption, small }

/// Text with a design-system style, so screens never set font sizes directly.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.variant = AppTextVariant.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.weight,
  });

  const AppText.header(this.data, {super.key, this.color, this.textAlign, this.maxLines})
      : variant = AppTextVariant.header2,
        weight = null;

  const AppText.subtitle(this.data, {super.key, this.textAlign, this.maxLines})
      : variant = AppTextVariant.callout,
        color = AppColors.textAccent,
        weight = null;

  final String data;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    final base = switch (variant) {
      AppTextVariant.header2 => AppTypography.header2,
      AppTextVariant.header3 => AppTypography.header3,
      AppTextVariant.subhead => AppTypography.subhead,
      AppTextVariant.title => AppTypography.titleMedium,
      AppTextVariant.callout => AppTypography.callout,
      AppTextVariant.body => AppTypography.caption1,
      AppTextVariant.bodyMedium => AppTypography.caption1Medium,
      AppTextVariant.caption => AppTypography.caption2,
      AppTextVariant.small => AppTypography.caption4Medium,
    };
    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: base.copyWith(color: color, fontWeight: weight),
    );
  }
}
