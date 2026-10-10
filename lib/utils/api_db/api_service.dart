import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Error from the backend, with a message that can be shown to the user.
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, [this.statusCode]);

  factory ApiException.fromStatus(int status) => ApiException(
        switch (status) {
          401 => 'API key rejected (401). Rebuild with the right API_KEY.',
          404 => 'Not found (404)',
          422 => 'Invalid request (422)',
          _ => 'Server error ($status)',
        },
        status,
      );

  @override
  String toString() => message;
}

/// Client for https://backend.jevrej.cz (contract: docs/HANDOFF.md).
class ApiService {
  static const String baseUrl = 'https://backend.jevrej.cz';

  /// Passed at build time: `--dart-define-from-file=.env.json`.
  static const String apiKey = String.fromEnvironment('API_KEY');

  /// Whether opening a conversation increments its `hits` counter.
  /// On in release builds only, so development runs keep the counters honest.
  static const bool countHits =
      bool.fromEnvironment('COUNT_HITS', defaultValue: kReleaseMode);

  static const Map<String, String> headers = {'x-api-key': apiKey};

  static final http.Client _client = http.Client();
  static final _log = Logger('api');

  /// Headers for loading [url]; the key is only ever sent to our backend.
  static Map<String, String> headersFor(String url) =>
      url.startsWith('$baseUrl/') ? headers : const {};

  /// URL of a media file from a message `uri`
  /// (`messages/inbox/<dir>/<type>/<file>` is served at `/inbox/<dir>/<type>/<file>`).
  /// Absolute URLs (old CDN links stored in some messages) are returned as they are.
  static String mediaUrl(String uri) {
    if (uri.startsWith('http://') || uri.startsWith('https://')) return uri;
    const prefix = 'messages/inbox/';
    final path = uri.startsWith(prefix) ? uri.substring(prefix.length) : uri;
    return '$baseUrl/inbox/${path.split('/').map(Uri.encodeComponent).join('/')}';
  }

  static String profilePhotoUrl(String collectionName) =>
      '$baseUrl/serve/photo/${Uri.encodeComponent(collectionName)}';

  static String _c(String collectionName) =>
      Uri.encodeComponent(collectionName);

  static Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    Map<String, String> extraHeaders = const {},
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers.addAll(headers)
      ..headers.addAll(extraHeaders);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    final watch = Stopwatch()..start();
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } catch (e) {
      throw ApiException('Network error: $e');
    }
    _log.info('$method ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''} '
        '-> ${response.statusCode} ${response.bodyBytes.length} B '
        '${watch.elapsedMilliseconds} ms');
    if (response.statusCode != 200) {
      throw ApiException.fromStatus(response.statusCode);
    }
    return _decode(response.bodyBytes);
  }

  /// Large payloads are decoded off the UI thread.
  static Future<dynamic> _decode(Uint8List bytes) => bytes.length > 64 * 1024
      ? compute(_decodeSync, bytes)
      : Future.value(_decodeSync(bytes));

  static dynamic _decodeSync(Uint8List bytes) => jsonDecode(utf8.decode(bytes));

  static List<Map<String, dynamic>> _list(dynamic data) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['error'] != null) {
      throw ApiException(data['error'].toString());
    }
    throw const ApiException('Unexpected response from server');
  }

  /// All conversations: `{name, messageCount, hits}` in no particular order.
  static Future<List<Map<String, dynamic>>> fetchCollections() async =>
      _list(await _send('GET', '/collections'));

  /// One page of a conversation, oldest first. Always paged: the unpaged
  /// endpoint returns whole conversations (tens of MB).
  static Future<List<Map<String, dynamic>>> fetchMessages(
    String collectionName, {
    required int offset,
    required int limit,
    int? fromDate,
    int? toDate,
    bool countHit = false,
  }) async =>
      _list(await _send(
        'GET',
        '/messages/${_c(collectionName)}',
        query: {
          'offset': '$offset',
          'limit': '$limit',
          if (fromDate != null) 'fromDate': '$fromDate',
          if (toDate != null) 'toDate': '$toDate',
        },
        extraHeaders:
            countHit && countHits ? const {'metrics': 'true'} : const {},
      ));

  static Future<int> fetchMessageCount(String collectionName) async =>
      (await _send('GET', '/messages/${_c(collectionName)}/count'))['count']
          as int;

  /// `{totalMessages, firstMessageAt, lastMessageAt, media, senders, perMonth}`.
  static Future<Map<String, dynamic>> fetchStats(String collectionName) async =>
      await _send('GET', '/stats/${_c(collectionName)}')
          as Map<String, dynamic>;

  /// Search message text. With [collectionName]: substring search in that
  /// conversation, oldest first. Otherwise across all conversations, either
  /// substring (slow, complete) or [fast] whole-word search (ranked, max 500).
  static Future<List<Map<String, dynamic>>> search(
    String query, {
    String? collectionName,
    bool fast = false,
  }) async =>
      _list(await _send('POST', '/search_text', body: {
        'query': query,
        if (collectionName != null) 'collectionName': collectionName,
        if (fast) 'mode': 'fast',
      }));

  /// Whether a profile photo file exists (HEAD, so nothing is downloaded).
  static Future<bool> profilePhotoExists(String collectionName) async {
    try {
      final response = await _client
          .head(Uri.parse(profilePhotoUrl(collectionName)), headers: headers);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Photo messages not sent by the owner, each with a `photos` list.
  static Future<List<Map<String, dynamic>>> fetchPhotos(
          String collectionName) async =>
      _list(await _send('GET', '/photos/${_c(collectionName)}'));

  static Future<String> uploadPhoto(
          String collectionName, List<int> jpegBytes) async =>
      (await _send('POST', '/upload/photo/${_c(collectionName)}',
          body: {'photo': base64Encode(jpegBytes)}))['message'] as String;

  static Future<String> deletePhoto(String collectionName) async =>
      (await _send('DELETE', '/delete/photo/${_c(collectionName)}'))['message']
          as String;
}
