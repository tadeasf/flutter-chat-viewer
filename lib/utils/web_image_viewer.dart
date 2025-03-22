import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'api_db/api_service.dart';

/// A web-compatible image viewer
class WebImageViewer extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget loadingWidget;
  final Widget errorWidget;

  const WebImageViewer({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingWidget = const CircularProgressIndicator(),
    this.errorWidget = const Icon(Icons.error),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        httpHeaders: ApiService.headers,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => Center(child: loadingWidget),
        errorWidget: (context, url, error) => Center(child: errorWidget),
      ),
    );
  }
}
