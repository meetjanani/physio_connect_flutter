import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network image that works on every platform.
///
/// Mobile: [CachedNetworkImage] (disk cache).
///
/// Web: Flutter's default (CanvasKit) image loading downloads the bytes with
/// `fetch`, which the browser blocks unless the image host sends CORS headers.
/// Firebase Storage buckets don't send them by default, so remote images
/// failed to show on the website. [WebHtmlElementStrategy.prefer] renders the
/// image with a plain `<img>` element instead, which needs no CORS.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorWidget;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    if (url.isEmpty) return _error(context);

    if (kIsWeb) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: placeholder == null
            ? null
            : (context, child, progress) => progress == null
                  ? child
                  : SizedBox(
                      width: width,
                      height: height,
                      child: placeholder!(context),
                    ),
        errorBuilder: (context, _, __) => _error(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder == null
          ? null
          : (context, _) => placeholder!(context),
      errorWidget: (context, _, __) => _error(context),
    );
  }

  Widget _error(BuildContext context) =>
      SizedBox(width: width, height: height, child: errorWidget?.call(context));
}
