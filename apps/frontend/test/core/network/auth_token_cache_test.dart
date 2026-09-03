import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/network/auth_token_cache.dart';

void main() {
  test('starts empty', () {
    final cache = AuthTokenCache();
    expect(cache.accessToken, isNull);
    expect(cache.refreshToken, isNull);
  });

  test('set stores both tokens', () {
    final cache = AuthTokenCache()..set(accessToken: 'access-1', refreshToken: 'refresh-1');
    expect(cache.accessToken, 'access-1');
    expect(cache.refreshToken, 'refresh-1');
  });

  test('set overwrites a previous pair', () {
    final cache = AuthTokenCache()
      ..set(accessToken: 'access-1', refreshToken: 'refresh-1')
      ..set(accessToken: 'access-2', refreshToken: 'refresh-2');
    expect(cache.accessToken, 'access-2');
    expect(cache.refreshToken, 'refresh-2');
  });

  test('clear empties both tokens', () {
    final cache = AuthTokenCache()
      ..set(accessToken: 'access-1', refreshToken: 'refresh-1')
      ..clear();
    expect(cache.accessToken, isNull);
    expect(cache.refreshToken, isNull);
  });
}
