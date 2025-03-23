import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:typed_data';
import 'url_formatter.dart';
import 'web_http_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../js_util.dart';

class ApiService {
  static const String baseUrl = 'https://backend.jevrej.cz';

  // API key getter that checks for web environment to use window.FLUTTER_ENV
  static String get apiKey {
    if (kIsWeb) {
      // Try to get the API key from window.FLUTTER_ENV in web mode
      final webApiKey = getApiKey();
      if (webApiKey != null && webApiKey.isNotEmpty) {
        return webApiKey;
      }
    }

    // Fallback to dotenv for native platforms or if web API key not available
    return dotenv.env['X_API_KEY'] ?? '';
  }

  static final Map<String, String> _profilePhotoUrls = {};

  static Map<String, String> get headers {
    final Map<String, String> baseHeaders = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };
    return baseHeaders;
  }

  static Map<String, String> get headersWithMetrics {
    final Map<String, String> baseHeaders = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'metrics': 'true',
    };
    return baseHeaders;
  }

  static Map<String, String> get videoHeaders {
    final Map<String, String> baseHeaders = {
      'x-api-key': apiKey,
      'Accept': 'video/mp4,*/*',
      'Connection': 'keep-alive',
    };
    return baseHeaders;
  }

  static Future<List<Map<String, dynamic>>> fetchCollections() async {
    final url = Uri.parse('$baseUrl/collections');

    if (kDebugMode) {
      print('Fetch Collections Request:');
      print('URL: $url');
      // print('Headers: $headers');
      // print('x-api-key: $apiKey');
    }

    http.Response response;
    if (kIsWeb) {
      response = await WebHttpClient.get(url, headers: headers);
    } else {
      response = await http.get(url, headers: headers);
    }

    if (kDebugMode) {
      print('Fetch Collections Response:');
      print('Status Code: ${response.statusCode}');
      // print('Body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic> && data.containsKey('error')) {
        throw Exception(data['error']);
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load collections: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>>
      fetchAlphabeticalCollections() async {
    final response = await http
        .get(Uri.parse('$baseUrl/collections/alphabetical'), headers: headers);

    if (kDebugMode) {
      print('Fetch Alphabetical Collections Response:');
      print('Status Code: ${response.statusCode}');
      // print('Body: ${response.body}');
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map<String, dynamic> && data.containsKey('error')) {
        throw Exception(data['error']);
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception(
          'Failed to load alphabetical collections: ${response.statusCode}');
    }
  }

  static Future<http.Response> get(String endpoint,
      {required Map<String, String> headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    if (kIsWeb) {
      return WebHttpClient.get(url, headers: headers);
    }

    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint,
      {Object? body, required Map<String, String> headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    if (kIsWeb) {
      return WebHttpClient.post(url, headers: headers, body: jsonEncode(body));
    }

    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  static Future<List<dynamic>> fetchMessages(String collectionName,
      {String? fromDate, String? toDate}) async {
    String url = '$baseUrl/messages/${Uri.encodeComponent(collectionName)}';
    if (fromDate != null || toDate != null) {
      List<String> queryParams = [];
      if (fromDate != null) queryParams.add('fromDate=$fromDate');
      if (toDate != null) queryParams.add('toDate=$toDate');
      url += '?${queryParams.join('&')}';
    }

    // if (kDebugMode) {
    //   print('Fetching messages with headers: $headersWithMetrics');
    // }

    http.Response response;
    if (kIsWeb) {
      response =
          await WebHttpClient.get(Uri.parse(url), headers: headersWithMetrics);
    } else {
      response = await http.get(Uri.parse(url), headers: headersWithMetrics);
    }

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
      // print('Response headers: ${response.headers}');
    }

    if (response.statusCode == 200) {
      final List<dynamic> messages =
          json.decode(utf8.decode(response.bodyBytes));
      messages.sort((a, b) =>
          (a['timestamp_ms'] as int).compareTo(b['timestamp_ms'] as int));
      return messages;
    } else {
      throw Exception('Failed to load messages: ${response.statusCode}');
    }
  }

  static Future<int> fetchMessageCount(String collectionName) async {
    final response = await http.get(
        Uri.parse(
            '$baseUrl/messages/${Uri.encodeComponent(collectionName)}/count'),
        headers: headers);
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['count'] as int;
    } else {
      throw Exception('Failed to load message count');
    }
  }

  static Future<bool> checkPhotoAvailability(String collectionName) async {
    final url =
        Uri.parse('$baseUrl/${Uri.encodeComponent(collectionName)}/photo');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['isPhotoAvailable'];
    } else {
      throw Exception('Failed to check photo availability');
    }
  }

  static Future<void> uploadPhoto(
      String collectionName, Map<String, String> photoData) async {
    final url = Uri.parse(
        '$baseUrl/upload/photo/${Uri.encodeComponent(collectionName)}');

    final response = await http.post(
      url,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(photoData),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to upload photo: ${response.statusCode}\n${response.body}');
    }
  }

  static String getPhotoUrl(String collectionName, String filename) {
    if (kDebugMode) {
      print('getPhotoUrl: $baseUrl/inbox/$collectionName/photos/$filename');
    }
    return UrlFormatter.formatMediaUrl(
      collectionName: collectionName,
      uri: filename,
      type: MediaType.photo,
    );
  }

  static String getVideoUrl(String collectionName, String uri) {
    return UrlFormatter.formatMediaUrl(
      collectionName: collectionName,
      uri: uri,
      type: MediaType.video,
    );
  }

  static String getAudioUrl(String collectionName, String uri) {
    // print the link we generate using the url formatter
    if (kDebugMode) {
      print(UrlFormatter.formatMediaUrl(
        collectionName: collectionName,
        uri: uri,
        type: MediaType.audio,
      ));
    }
    return UrlFormatter.formatMediaUrl(
      collectionName: collectionName,
      uri: uri,
      type: MediaType.audio,
    );
  }

  static String getProfilePhotoUrl(String collectionName) {
    return UrlFormatter.formatProfilePhotoUrl(collectionName);
  }

  static Future<List<Map<String, dynamic>>> fetchPhotos(
      String collectionName) async {
    final response = await get('/photos/${Uri.encodeComponent(collectionName)}',
        headers: headers); // Use headers here
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load photos: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> deletePhoto(String collectionName) async {
    final url = Uri.parse(
        '$baseUrl/delete/photo/${Uri.encodeComponent(collectionName)}');

    http.Response response;
    if (kIsWeb) {
      response = await WebHttpClient.delete(
        url,
        headers: headers,
        body: '{}', // Send an empty JSON object as the body
      );
    } else {
      response = await http.delete(
        url,
        headers: headers,
        body: '{}', // Send an empty JSON object as the body
      );
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Clear the cached photo URL for this collection
      _profilePhotoUrls.remove(collectionName);
      return {
        'success': true,
        'message': data['message'],
      };
    } else {
      String errorMessage;
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? 'Failed to delete photo';
      } catch (e) {
        errorMessage = 'Failed to delete photo: ${response.body}';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCollectionsPaginated() async {
    return fetchCollections(); // Since pagination is not implemented on the server side
  }

  static String getUrlWithApiKey(String endpoint) {
    final Uri uri = Uri.parse('$baseUrl$endpoint');
    final newQueryParameters = Map<String, String>.from(uri.queryParameters)
      ..['api_key'] = apiKey;
    return uri.replace(queryParameters: newQueryParameters).toString();
  }

  static Future<http.Response> delete(String endpoint,
      {required Map<String, String> headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    if (kIsWeb) {
      return WebHttpClient.delete(url, headers: headers);
    }

    return await http.delete(url, headers: headers);
  }

  // This method can be used to get a URL with the API key in the header
  static Future<String> getUrlWithApiKeyHeader(String url) async {
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return url;
    } else {
      throw Exception('Failed to access URL: ${response.statusCode}');
    }
  }

  // This method will be used to get image URLs with the API key
  static Future<String> getSecureImageUrl(String uri) async {
    // Parse the URI to extract collection name and filename
    final parts = uri.split('/');
    if (parts.length < 2) {
      throw Exception('Invalid URI format');
    }

    final collectionName = parts[parts.length - 2];
    final filename = parts[parts.length - 1];

    final url = getPhotoUrl(collectionName, filename);
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return url;
    } else {
      throw Exception('Failed to get secure image URL: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> performCrossCollectionSearch(
      String query) async {
    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final response = await post(
          '/search_text',
          body: {'query': query},
          headers: headers,
        );

        if (response.statusCode == 200) {
          final results = json.decode(utf8.decode(response.bodyBytes));

          // If we get less than 5 messages and it's not the last retry, try again
          if (results is List &&
              results.length < 5 &&
              retryCount < maxRetries - 1) {
            await Future.delayed(retryDelay);
            retryCount++;
            continue;
          }

          return results;
        } else {
          throw Exception(
              'Failed to perform cross-collection search: ${response.statusCode}');
        }
      } catch (e) {
        if (retryCount == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(retryDelay);
        retryCount++;
      }
    }

    throw Exception(
        'Failed to perform cross-collection search after $maxRetries attempts');
  }

  static Future<Uint8List> fetchAudioData(String url) async {
    try {
      http.Response response;
      if (kIsWeb) {
        response = await WebHttpClient.get(
          Uri.parse(url),
          headers: headers,
        );
      } else {
        response = await http.get(
          Uri.parse(url),
          headers: headers,
        );
      }

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load audio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load audio: $e');
    }
  }

  // Add method to fetch video data if needed
  static Future<Uint8List> fetchVideoData(String url) async {
    try {
      // Try first without Range header
      http.Response response;
      if (kIsWeb) {
        response = await WebHttpClient.get(
          Uri.parse(url),
          headers: videoHeaders,
        );
      } else {
        response = await http.get(
          Uri.parse(url),
          headers: videoHeaders,
        );
      }

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      // If that fails, try with a simple GET request with basic headers
      http.Response fallbackResponse;
      if (kIsWeb) {
        fallbackResponse = await WebHttpClient.get(
          Uri.parse(url),
          headers: {
            'x-api-key': apiKey,
            'Accept': '*/*',
          },
        );
      } else {
        fallbackResponse = await http.get(
          Uri.parse(url),
          headers: {
            'x-api-key': apiKey,
            'Accept': '*/*',
          },
        );
      }

      if (fallbackResponse.statusCode == 200) {
        return fallbackResponse.bodyBytes;
      }

      throw Exception('Failed to load video: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load video: $e');
    }
  }

  /// Returns a direct image URL for web downloads
  /// This URL can be used to open in a new tab for direct downloads
  static String getWebDownloadUrl(String collectionName, String filename) {
    return '$baseUrl/inbox/${Uri.encodeComponent(collectionName)}/photos/$filename';
  }
}
