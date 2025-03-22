import 'package:web/web.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;

/// A web-specific image viewer that uses HTML directly to bypass CORS issues
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
    // The key is this bypasses Flutter's HTTP client entirely
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final img = document.createElement('img') as HTMLImageElement
        ..src = widget.imageUrl
        ..style.setProperty('object-fit', _getBrowserObjectFit(widget.fit))
        ..style.setProperty('width', '100%')
        ..style.setProperty('height', '100%');
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
