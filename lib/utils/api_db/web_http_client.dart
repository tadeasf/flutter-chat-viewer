import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Web-specific HTTP client to handle CORS issues
class WebHttpClient {
  static final Logger _logger = Logger('WebHttpClient');

  static Future<http.Response> get(Uri url,
      {Map<String, String>? headers}) async {
    if (!kIsWeb) {
      return http.get(url, headers: headers);
    }

    // Web-specific implementation
    try {
      // First try with regular HTTP
      final response = await http.get(url, headers: headers);

      // If successful, return the response
      if (response.statusCode != 0) {
        return response;
      }

      // If we got status code 0 (CORS issue), throw an exception to try the fallback
      throw Exception('CORS error detected');
    } catch (e) {
      // Log the error for debugging
      _logger.warning('CORS error occurred: $e');

      // Create a modified URL with additional parameters to help bypass CORS
      final modifiedUrl = url.replace(
          queryParameters: {...url.queryParameters, 'cors_bypass': 'true'});

      // Try again with modified headers
      final modifiedHeaders = {...?headers};
      modifiedHeaders['Accept'] = '*/*';

      return http.get(modifiedUrl, headers: modifiedHeaders);
    }
  }

  static Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    if (!kIsWeb) {
      return http.post(url, headers: headers, body: body);
    }

    // Web-specific implementation
    try {
      // First try with regular HTTP
      final response = await http.post(url, headers: headers, body: body);

      // If successful, return the response
      if (response.statusCode != 0) {
        return response;
      }

      // If we got status code 0 (CORS issue), throw an exception to try the fallback
      throw Exception('CORS error detected');
    } catch (e) {
      // Log the error for debugging
      _logger.warning('CORS error occurred: $e');

      // Create a modified URL with additional parameters to help bypass CORS
      final modifiedUrl = url.replace(
          queryParameters: {...url.queryParameters, 'cors_bypass': 'true'});

      // Try again with modified headers
      final modifiedHeaders = {...?headers};
      modifiedHeaders['Accept'] = '*/*';

      return http.post(modifiedUrl, headers: modifiedHeaders, body: body);
    }
  }

  static Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body}) async {
    if (!kIsWeb) {
      return http.delete(url, headers: headers, body: body);
    }

    // Web-specific implementation
    try {
      // First try with regular HTTP
      final response = await http.delete(url, headers: headers, body: body);

      // If successful, return the response
      if (response.statusCode != 0) {
        return response;
      }

      // If we got status code 0 (CORS issue), throw an exception to try the fallback
      throw Exception('CORS error detected');
    } catch (e) {
      // Log the error for debugging
      _logger.warning('CORS error occurred: $e');

      // Create a modified URL with additional parameters to help bypass CORS
      final modifiedUrl = url.replace(
          queryParameters: {...url.queryParameters, 'cors_bypass': 'true'});

      // Try again with modified headers
      final modifiedHeaders = {...?headers};
      modifiedHeaders['Accept'] = '*/*';

      return http.delete(modifiedUrl, headers: modifiedHeaders, body: body);
    }
  }
}
