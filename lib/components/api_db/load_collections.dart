import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

Future<void> loadCollections(
    Function(List<Map<String, dynamic>>) updateCollections) async {
  try {
    // Try to load cached collections first
    final prefs = await SharedPreferences.getInstance();
    final cachedCollections = prefs.getString('cachedCollections');

    if (cachedCollections != null) {
      final List<Map<String, dynamic>> collections =
          List<Map<String, dynamic>>.from(json.decode(cachedCollections));
      updateCollections(collections);
    }

    // Fetch new collections
    final loadedCollections = await ApiService.fetchCollections();
    if (kDebugMode) {
      print('Loaded collections: $loadedCollections');
    }

    if (loadedCollections.isEmpty) {
      if (kDebugMode) {
        print('No collections found');
      }
      // You might want to show a message to the user here
    }

    updateCollections(loadedCollections);

    // Cache the new collections
    await prefs.setString('cachedCollections', json.encode(loadedCollections));
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching collections: $e');
    }
    // You might want to show an error message to the user here
  }
}

Future<List<Map<String, dynamic>>> loadMoreCollections() async {
  try {
    return await ApiService.fetchAlphabeticalCollections();
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching more collections: $e');
    }
    return [];
  }
}
