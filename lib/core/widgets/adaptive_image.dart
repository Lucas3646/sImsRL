import 'dart:io';

import 'package:flutter/material.dart';

import 'package:simsrl/core/theme/app_theme.dart';

class AdaptiveImage extends StatelessWidget {
  const AdaptiveImage({
    required this.path,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.semanticLabel,
    super.key,
  });

  final String path;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (path.startsWith('demo://')) {
      final color = _parseColor(path.substring('demo://'.length));
      child = ColoredBox(
        color: color,
        child: Center(
          child: Icon(
            Icons.checkroom_rounded,
            size: 46,
            color:
                ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                ? Colors.white70
                : AppColors.ink.withValues(alpha: 0.55),
          ),
        ),
      );
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      child = Image.network(
        path,
        fit: fit,
        semanticLabel: semanticLabel,
        errorBuilder: (_, __, ___) => const _ImageError(),
      );
    } else {
      child = Image.file(
        File(path),
        fit: fit,
        semanticLabel: semanticLabel,
        errorBuilder: (_, __, ___) => const _ImageError(),
      );
    }
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Color _parseColor(String value) {
    final hex = value.replaceAll('#', '');
    final parsed = int.tryParse('FF$hex', radix: 16);
    return parsed == null ? AppColors.lavender : Color(parsed);
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.line,
    child: Center(
      child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
    ),
  );
}
