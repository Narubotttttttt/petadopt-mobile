class ApiConfig {
  
  static const String serverIp = '192.168.1.46';
  static const String serverPort = '8000';

  static const String host = 'http://$serverIp:$serverPort';
  static const String baseUrl = '$host/api';
  static const String storageBaseUrl = '$host/storage';

  // Request timeouts
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 30);

  /// Normalizes media URLs for pet images, avatars, and documents.
  /// Handles relative paths, local storage directories, and development IP overrides.
  static String normalizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty || url == 'null') {
      return '';
    }
    final baseUri = Uri.parse(baseUrl);
    final hostPrefix = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';

    if (url.startsWith('/')) {
      return '$hostPrefix$url';
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return '$hostPrefix/storage/$url';
    }

    if (url.contains('/storage/')) {
      final imgUri = Uri.tryParse(url);
      if (imgUri != null) {
        return imgUri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        ).toString();
      }
    }

    if (url.contains('localhost') || url.contains('127.0.0.1') || url.contains('10.0.2.2')) {
      final imgUri = Uri.tryParse(url);
      if (imgUri != null) {
        return imgUri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        ).toString();
      }
    }
    return url;
  }
}
