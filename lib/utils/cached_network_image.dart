import 'package:flutter/material.dart';
import 'package:physio_connect/utils/app_network_image.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class CatchedImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit? boxFit;

  const CatchedImageWidget({
    super.key,
    this.imageUrl,
    this.height = 100,
    this.width = 100,
    this.boxFit = BoxFit.fill,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) return _fallback;

    // Same look as before (cover-fit), but via AppNetworkImage so it also
    // renders on the website (a DecorationImage can't use an <img> element).
    return AppNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_) => _fallback,
    );
  }

  static final Widget _fallback = Container(
    height: 160,
    color: AppColors.therapyPurple.withOpacity(0.3),
    child: Center(
      child: Icon(Icons.healing, size: 60, color: AppColors.therapyPurple),
    ),
  );
}
