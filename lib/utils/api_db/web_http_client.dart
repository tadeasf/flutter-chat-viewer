import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Web-specific HTTP client that forwards requests to the standard HTTP client
class WebHttpClient {
  static Future<http.Response> get(Uri url,
      {Map<String, String>? headers}) async {
    if (!kIsWeb) {
      return http.get(url, headers: headers);
    }

    // Web implementation now directly uses standard HTTP
    return http.get(url, headers: headers);
  }

  static Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    if (!kIsWeb) {
      return http.post(url, headers: headers, body: body);
    }

    // Web implementation now directly uses standard HTTP
    return http.post(url, headers: headers, body: body);
  }

  static Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    if (!kIsWeb) {
      return http.delete(url, headers: headers, body: body);
    }

    // Web implementation now directly uses standard HTTP
    return http.delete(url, headers: headers, body: body);
  }
}
