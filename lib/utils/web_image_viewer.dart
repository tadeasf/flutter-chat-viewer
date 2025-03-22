import 'package:web/web.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'api_db/api_service.dart';

/// A web-specific image viewer that renders images directly using HTML
class WebImageViewer extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const WebImageViewer({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    Widget loadingWidget = const CircularProgressIndicator(),
    Widget errorWidget = const Icon(Icons.error),
  });

  @override
  State<WebImageViewer> createState() => _WebImageViewerState();
}

class _WebImageViewerState extends State<WebImageViewer> {
  final String _viewType = 'img-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    // Register a view factory with a plain img element
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final img = document.createElement('img') as HTMLImageElement
        ..style.setProperty('object-fit', _getBrowserObjectFit(widget.fit))
        ..style.setProperty('width', '100%')
        ..style.setProperty('height', '100%');

      // Create fetch request with headers to get image with authorization
      final apiKey = ApiService.apiKey;
      final imgUrl = widget.imageUrl;

      // Create a blob URL with the API key header
      final request = XMLHttpRequest();
      request.open('GET', imgUrl);
      request.setRequestHeader('x-api-key', apiKey);
      request.responseType = 'blob';

      request.onLoad.listen((event) {
        if (request.status == 200) {
          final blob = request.response as Blob;
          final url = URL.createObjectURL(blob);
          img.src = url;
        } else {
          img.alt = 'Failed to load image';
        }
      });

      request.onError.listen((event) {
        img.alt = 'Error loading image';
      });

      request.send();

      return img;
    });
  }

  String _getBrowserObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      default:
        return 'cover';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
