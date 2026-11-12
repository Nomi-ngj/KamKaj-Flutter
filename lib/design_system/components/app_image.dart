import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Cached network image with tokenised placeholder and error states.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final source = url;
    final Widget child = source == null || source.isEmpty
        ? const _ImagePlaceholder()
        : CachedNetworkImage(
            imageUrl: source,
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: _cacheWidth(context),
            placeholder: (_, _) => const _ImagePlaceholder(),
            errorWidget: (_, _, _) => const _ImagePlaceholder(),
          );

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  int? _cacheWidth(BuildContext context) {
    final w = width;
    if (w == null || !w.isFinite) return null;
    return (w * MediaQuery.devicePixelRatioOf(context)).round();
  }
}

/// Bundled asset image that degrades to a placeholder when the file has not
/// been exported from Figma yet.
class AppAssetImage extends StatelessWidget {
  const AppAssetImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = BorderRadius.zero,
    this.semanticLabel,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => SizedBox(
          width: width,
          height: height,
          child: _ImagePlaceholder(icon: placeholderIcon),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.icon = Icons.image_outlined});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(icon, color: AppColors.textTertiary, size: AppDimensions.iconXl),
      ),
    );
  }
}
