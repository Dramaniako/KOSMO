import 'dart:convert';
import 'package:flutter/material.dart';

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
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String.trim());
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
