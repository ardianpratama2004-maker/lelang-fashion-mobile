import 'package:flutter_test/flutter_test.dart';
import 'package:pelelangan_produk_fashion/src/core/config/app_config.dart';

void main() {
  group('normalizeApiBaseUrl', () {
    test('adds api path to bare public domain', () {
      expect(
        normalizeApiBaseUrl('lelang-fashion.example.com'),
        'https://lelang-fashion.example.com/api',
      );
    });

    test('keeps existing api path', () {
      expect(
        normalizeApiBaseUrl('https://lelang-fashion.example.com/api'),
        'https://lelang-fashion.example.com/api',
      );
    });

    test('uses http for local hosts and strips query fragments', () {
      expect(
        normalizeApiBaseUrl('127.0.0.1:8000/api?debug=true#app'),
        'http://127.0.0.1:8000/api',
      );
    });

    test('falls back to Android emulator backend when empty', () {
      expect(normalizeApiBaseUrl('   '), 'http://10.0.2.2:8000/api');
    });
  });

  group('resolveApiBaseUrl', () {
    test('prefers dotenv API_BASE_URL over dart define values', () {
      expect(
        resolveApiBaseUrl(
          apiBaseUrl: 'local.test',
          dartDefine: 'production.test',
        ),
        'https://local.test/api',
      );
    });

    test('uses GitHub-generated dotenv value when present', () {
      expect(
        resolveApiBaseUrl(apiBaseUrl: 'https://api.example.test/api'),
        'https://api.example.test/api',
      );
    });

    test('uses dart define value when dotenv is empty', () {
      expect(
        resolveApiBaseUrl(dartDefine: 'production.example.test'),
        'https://production.example.test/api',
      );
    });
  });
}
