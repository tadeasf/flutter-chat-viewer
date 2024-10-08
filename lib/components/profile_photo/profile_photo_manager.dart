import 'dart:convert';
import '../api_db/api_service.dart';
import 'package:logging/logging.dart';

class ProfilePhotoManager {
  static final Logger _logger = Logger('ProfilePhotoManager');
  static final Map<String, String?> _profilePhotoUrls = {};

  static Future<String?> getProfilePhotoUrl(String collectionName) async {
    try {
      final response = await ApiService.get(
        '/messages/${Uri.encodeComponent(collectionName)}/photo',
        headers: ApiService.headers, // Use ApiService.headers here
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isPhotoAvailable']) {
          return ApiService.getProfilePhotoUrl(collectionName);
        }
      }
      _profilePhotoUrls.remove(collectionName);
      return null;
    } catch (e) {
      _logger.warning('Error fetching profile photo URL: $e');
      _profilePhotoUrls.remove(collectionName);
      return null;
    }
  }

  static void clearCache(String collectionName) {
    _profilePhotoUrls.remove(collectionName);
  }

  static void clearAllCache() {
    _profilePhotoUrls.clear();
  }
}
