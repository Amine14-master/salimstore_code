import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageUtils {
  static Widget buildNetworkImage({
    required String imageUrl,
    required Widget placeholder,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              color: Colors.grey[400],
              size: width != null ? width * 0.5 : 24,
            ),
          ),
    );
  }

  static Widget buildEnhancedImage({
    required String imageUrl,
    required String productName,
    required String categoryId,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    bool enableShimmer = true,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => enableShimmer
            ? Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: width,
                  height: height,
                  color: Colors.white,
                ),
              )
            : Container(width: width, height: height, color: Colors.grey[200]),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: Colors.grey[400],
                size: (width ?? 50) * 0.4,
              ),
              if (width != null && width > 60)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    productName.length > 20
                        ? '${productName.substring(0, 20)}...'
                        : productName,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
