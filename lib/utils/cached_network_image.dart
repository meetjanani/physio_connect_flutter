import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:physio_connect/utils/theme/app_colors.dart';

class CatchedImageWidget extends StatefulWidget {
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
  State<CatchedImageWidget> createState() => _CatchedImageWidgetState();
}

class _CatchedImageWidgetState extends State<CatchedImageWidget> {
  get boxfit => null;

  @override
  Widget build(BuildContext context) {
    // If no image URL, return fallback immediately
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return fallbackWidget;
    }

    return CachedNetworkImage(
      color: Colors.transparent,
      width: widget.width,
      height: widget.height,
      fit: boxfit,
      imageBuilder: (context, imageProvider) => Container(
        width: widget.width, // 80.0
        height: widget.height, // 80.0
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
      imageUrl: widget.imageUrl!,
      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => fallbackWidget,
    );
  }

  Widget fallbackWidget = Container(
    height: 160,
    color: AppColors.therapyPurple.withOpacity(0.3),
    child: Center(
      child: Icon(Icons.healing, size: 60, color: AppColors.therapyPurple),
    ),
  );
}
