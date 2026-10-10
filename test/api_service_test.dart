import 'package:flutter_test/flutter_test.dart';
import 'package:meta_chat_viewer/utils/api_db/api_service.dart';

void main() {
  group('mediaUrl', () {
    test('maps message uris to /inbox', () {
      expect(
        ApiService.mediaUrl(
            'messages/inbox/romanjordan_1450956104924789/photos/a_b.jpg'),
        'https://backend.jevrej.cz/inbox/romanjordan_1450956104924789/photos/a_b.jpg',
      );
    });

    test('encodes each path segment', () {
      expect(
        ApiService.mediaUrl('messages/inbox/dir/audio/a b#1.aac'),
        'https://backend.jevrej.cz/inbox/dir/audio/a%20b%231.aac',
      );
    });

    test('keeps absolute urls as they are', () {
      const cdn = 'https://scontent.xx.fbcdn.net/v/x.gif?oe=63E1&_nc=1';
      expect(ApiService.mediaUrl(cdn), cdn);
    });
  });

  test('the api key is only sent to our backend', () {
    expect(ApiService.headersFor('https://backend.jevrej.cz/inbox/a.jpg'),
        ApiService.headers);
    expect(
        ApiService.headersFor('https://scontent.xx.fbcdn.net/x.jpg'), isEmpty);
    expect(ApiService.headersFor('https://backend.jevrej.cz.evil.com/x.jpg'),
        isEmpty);
  });

  test('status codes become readable errors', () {
    expect(ApiException.fromStatus(401).message, contains('API key'));
    expect(ApiException.fromStatus(500).statusCode, 500);
    expect(ApiException.fromStatus(422).message, contains('422'));
  });
}
