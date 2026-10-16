import 'package:flutter_dotenv/flutter_dotenv.dart';

const _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

final apiBaseUrl = resolveApiBaseUrl(
  apiBaseUrl: _env('API_BASE_URL'),
  dartDefine: _apiBaseUrlDefine,
);

String resolveApiBaseUrl({
  String? apiBaseUrl,
  String dartDefine = '',
}) {
  for (final value in [
    apiBaseUrl,
    dartDefine,
  ]) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return normalizeApiBaseUrl(trimmed);
    }
  }

  return normalizeApiBaseUrl('http://10.0.2.2:8000/api');
}

String? _env(String key) {
  try {
    return dotenv.maybeGet(key);
  } catch (_) {
    return null;
  }
}

String normalizeApiBaseUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'http://10.0.2.2:8000/api';

  final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z\d+\-.]*://').hasMatch(trimmed);
  final hostCandidate = trimmed.split('/').first;
  final localHost =
      hostCandidate.startsWith('localhost') ||
      hostCandidate.startsWith('127.') ||
      RegExp(r'^\d{1,3}(\.\d{1,3}){3}(:\d+)?$').hasMatch(hostCandidate);
  final withScheme = hasScheme
      ? trimmed
      : '${localHost ? 'http' : 'https'}://$trimmed';

  final uri = Uri.parse(withScheme);
  final normalizedPath = uri.path.replaceAll(RegExp(r'/+$'), '');

  if (normalizedPath.isEmpty) {
    return _cleanUri(uri, '/api').toString();
  }

  return _cleanUri(uri, normalizedPath).toString();
}

Uri _cleanUri(Uri uri, String path) {
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: path,
  );
}
