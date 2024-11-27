import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

Future<void> loadCollections(
    Function(List<Map<String, dynamic>>) updateCollections) async {
  int maxRetries = 3;
  int currentTry = 0;

  while (currentTry < maxRetries) {
    try {
      // Fetch new collections first
      final loadedCollections = await ApiService.fetchCollections();

      if (loadedCollections.isNotEmpty) {
        updateCollections(loadedCollections);
        // Cache the new collections
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'cachedCollections', json.encode(loadedCollections));
        return; // Success, exit the retry loop
      }

      // If we get here with empty collections, increment retry counter
      currentTry++;
      if (currentTry < maxRetries) {
        await Future.delayed(
            Duration(seconds: 2 * currentTry)); // Exponential backoff
      }
    } catch (e) {
      currentTry++;
      if (currentTry < maxRetries) {
        await Future.delayed(
            Duration(seconds: 2 * currentTry)); // Exponential backoff
      }
    }
  }

  // Only use cache if all retries failed
  final prefs = await SharedPreferences.getInstance();
  final cachedCollections = prefs.getString('cachedCollections');
  if (cachedCollections != null) {
    final List<Map<String, dynamic>> collections =
        List<Map<String, dynamic>>.from(json.decode(cachedCollections));
    updateCollections(collections);
  }
}

Future<List<Map<String, dynamic>>> loadMoreCollections() async {
  try {
    return await ApiService.fetchAlphabeticalCollections();
  } catch (e) {
    return [];
  }
}

Future<void> retryLoadCollections(
    Function(List<Map<String, dynamic>>) updateCollections) async {
  // Clear the cache first to force a fresh load
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('cachedCollections');

  // Attempt to load collections again
  return loadCollections(updateCollections);
}
