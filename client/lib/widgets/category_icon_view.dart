import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

class CategoryIconView extends StatelessWidget {
  final String? iconUrl;
  final IconData fallbackIcon;
  final double size;
  final Color fallbackColor;
  final double borderRadius;
  final bool clipOval;
  final bool showLoader;
  final Color? overlayColor;
  final bool expandToFill;

  const CategoryIconView({
    super.key,
    required this.iconUrl,
    required this.fallbackIcon,
    required this.size,
    required this.fallbackColor,
    this.borderRadius = 16,
    this.clipOval = false,
    this.showLoader = true,
    this.overlayColor,
    this.expandToFill = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = iconUrl?.trim();
    if (expandToFill) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : size;
          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : size;
          return _buildImage(url: url, width: width, height: height);
        },
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: _buildImage(url: url, width: size, height: size),
    );
  }

  Widget _wrapWithOverlay(Widget child) {
    if (overlayColor == null) {
      return child;
    }
    return ColorFiltered(
      colorFilter: ColorFilter.mode(overlayColor!, BlendMode.srcATop),
      child: child,
    );
  }

  Widget _buildImage({
    required String? url,
    required double width,
    required double height,
  }) {
    final fallback = _buildFallback(width, height);

    // If URL is provided, prioritize it and use contain fit to show full image
    if (url != null && url.isNotEmpty) {
      Widget image = Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) {
          // If URL fails, show empty container instead of fallback icon
          return Container(
            width: width,
            height: height,
            color: Colors.transparent,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return _wrapWithOverlay(child);
          }
          if (!showLoader) {
            return _wrapWithOverlay(child);
          }
          return Shimmer.fromColors(
            baseColor: AppTheme.primaryColor.withOpacity(0.25),
            highlightColor: Colors.white,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          );
        },
      );

      if (clipOval) {
        image = ClipOval(child: image);
      } else if (borderRadius > 0) {
        image = ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: image,
        );
      }

      if (!showLoader) {
        return _wrapWithOverlay(image);
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: Lottie.asset(
              'lib/assets/animations/category_loader.json',
              repeat: true,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: width, height: height, child: image),
        ],
      );
    }

    // No URL, use fallback icon
    return fallback;
  }

  Widget _buildFallback(double width, double height) {
    final sizeHint = math.min(width, height);
    final fallbackIconWidget = Icon(
      fallbackIcon,
      color: Colors.white,
      size: sizeHint * 0.48,
    );

    Widget content = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            fallbackColor.withOpacity(0.95),
            fallbackColor.withOpacity(0.6),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: fallbackIconWidget,
    );

    if (clipOval) {
      content = ClipOval(child: content);
    } else if (borderRadius > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}
