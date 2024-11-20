import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;

class ApiService {
  static const String baseUrl = 'https://backend.jevrej.cz';
  static const String apiKey = '0tXEQJs2QUHK';
  static final Map<String, String> _profilePhotoUrls = {};

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      };

  static Future<List<Map<String, dynamic>>> fetchCollections() async {
    final response =
        await http.get(Uri.parse('$baseUrl/collections'), headers: headers);

    if (kDebugMode) {
      print('Fetch Collections Response:');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
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
      print('Body: ${response.body}');
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
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint,
      {Object? body, required Map<String, String> headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');
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
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load messages');
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
    if (filename.startsWith('https')) {
      return filename;
    }
    
    // If it's a full URI path (like 'inbox/collection/photos/filename.jpg')
    if (filename.startsWith('inbox/')) {
      return '$baseUrl/$filename';
    }
    
    // For profile photos and direct photo access
    if (filename.startsWith('serve/photo/')) {
      return '$baseUrl/$filename';
    }
    
    // For gallery photos
    return '$baseUrl/inbox/$collectionName/photos/$filename';
  }

  static String getProfilePhotoUrl(String collectionName) {
    return getUrlWithApiKey(
        '/serve/photo/${Uri.encodeComponent(collectionName)}');
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
    final response = await http.delete(
      url,
      headers: headers,
      body: '{}', // Send an empty JSON object as the body
    );

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
    final response = await post(
      '/search',
      body: {'query': query},
      headers: headers, // This includes the x-api-key
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception(
          'Failed to perform cross-collection search: ${response.statusCode}');
    }
  }
}
