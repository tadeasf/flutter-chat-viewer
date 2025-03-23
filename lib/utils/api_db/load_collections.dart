import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

// Maximum age for cached collections (5 minutes)
const int _maxCacheAgeMinutes = 5;

Future<void> loadCollections(
    Function(List<Map<String, dynamic>>) updateCollections) async {
  // Try to load from cache first
  final prefs = await SharedPreferences.getInstance();
  final cachedCollections = prefs.getString('cachedCollections');
  final cachedTimestamp = prefs.getInt('cachedCollectionsTimestamp') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;

  // Check if we have valid cache (not too old)
  final cacheAge = now - cachedTimestamp;
  final cacheValid =
      cachedCollections != null && cacheAge < _maxCacheAgeMinutes * 60 * 1000;

  if (cacheValid) {
    // Use cached data if available and not expired
    final List<Map<String, dynamic>> collections =
        List<Map<String, dynamic>>.from(json.decode(cachedCollections));
    updateCollections(collections);

    // Still fetch in background to update cache asynchronously
    _fetchAndUpdateCache(updateCollections, false);
    return;
  }

  // No valid cache, fetch directly
  await _fetchAndUpdateCache(updateCollections, true);
}

Future<void> _fetchAndUpdateCache(
    Function(List<Map<String, dynamic>>) updateCollections,
    bool updateUI) async {
  int maxRetries = 3;
  int currentTry = 0;

  while (currentTry < maxRetries) {
    try {
      // Fetch new collections
      final loadedCollections = await ApiService.fetchCollections();

      if (loadedCollections.isNotEmpty) {
        // Only update UI if needed
        if (updateUI) {
          updateCollections(loadedCollections);
        }

        // Cache the new collections
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'cachedCollections', json.encode(loadedCollections));
        // Also cache timestamp
        await prefs.setInt('cachedCollectionsTimestamp',
            DateTime.now().millisecondsSinceEpoch);
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

  // If we get here and need to update UI but have no new data,
  // try using cache regardless of age as fallback
  if (updateUI) {
    final prefs = await SharedPreferences.getInstance();
    final cachedCollections = prefs.getString('cachedCollections');
    if (cachedCollections != null) {
      final List<Map<String, dynamic>> collections =
          List<Map<String, dynamic>>.from(json.decode(cachedCollections));
      updateCollections(collections);
    }
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
  await prefs.remove('cachedCollectionsTimestamp');

  // Attempt to load collections again with forced refresh
  return _fetchAndUpdateCache(updateCollections, true);
}
