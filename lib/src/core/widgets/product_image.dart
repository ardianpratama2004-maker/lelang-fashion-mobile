import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({required this.url, required this.height, super.key});

  final String? url;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _placeholder(Icons.checkroom_outlined);
    }

    return Image.network(
      url!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(Icons.photo_outlined, progress: progress);
      },
      errorBuilder: (context, error, stackTrace) =>
          Container(child: _placeholder(Icons.image_not_supported_outlined)),
    );
  }

  Widget _placeholder(IconData icon, {ImageChunkEvent? progress}) {
    final value = progress != null && progress.expectedTotalBytes != null
        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
        : null;

    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.brand50,
      alignment: Alignment.center,
      child: progress == null
          ? Icon(icon, color: AppColors.brand500, size: 34)
          : SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: value,
                color: AppColors.brand700,
              ),
            ),
    );
  }
}
