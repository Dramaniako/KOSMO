import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Global cache for decoded Base64 image bytes to prevent redundant CPU-heavy decoding on rebuilds/scrolling
final Map<String, Uint8List> _base64Cache = {};

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const CustomImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? const Icon(Icons.broken_image);
    }
    
    if (imageUrl.startsWith('data:')) {
      try {
        Uint8List? bytes = _base64Cache[imageUrl];
        if (bytes == null) {
          final base64String = imageUrl.split(',').last;
          bytes = base64Decode(base64String.trim());
          _base64Cache[imageUrl] = bytes;
        }
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => errorWidget ?? const Icon(Icons.broken_image),
        );
      } catch (_) {
        return errorWidget ?? const Icon(Icons.broken_image);
      }
    }
    
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => errorWidget ?? const Icon(Icons.broken_image),
    );
  }
}
