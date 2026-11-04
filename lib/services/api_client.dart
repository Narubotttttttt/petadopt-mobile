import 'package:mobile_petadopt/services/network_service.dart';

class ApiClient {
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> headersWithToken(String? token) => {
    ...defaultHeaders,
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  /// Returns true if an exception is caused by lost internet, DNS failure, or request timeout
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    final str = error.toString().toLowerCase();
    final isNet = str.contains('socketexception') ||
        str.contains('timeoutexception') ||
        str.contains('clientexception') ||
        str.contains('failed host lookup') ||
        str.contains('network is unreachable') ||
        str.contains('connection refused') ||
        str.contains('connection timed out') ||
        str.contains('connection reset') ||
        str.contains('connection closed') ||
        str.contains('handshakeexception') ||
        str.contains('no address associated with hostname') ||
        str.contains('os error: network is unreachable') ||
        str.contains('software caused connection abort');

    if (isNet) {
      NetworkService.instance.notifyConnectionLost();
    }
    return isNet;
  }

  /// Default user-friendly error message for connection drops
  static const String networkErrorMessage =
      'Connection lost. Unable to reach the server. Please check your internet connection and try again.';

  /// Formats any caught error into a friendly, clear user message
  static String formatUserErrorMessage(
    dynamic error, {
    String fallback = 'An unexpected error occurred. Please try again.',
  }) {
    if (isNetworkError(error)) {
      return networkErrorMessage;
    }
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error?.toString() ?? fallback;
  }

  /// Parses error messages from Laravel API error responses
  static String extractErrorMessage(
    Map<String, dynamic>? data, {
    String fallback = 'An unexpected error occurred. Please try again.',
  }) {
    if (data == null) return fallback;

    final errors = data['errors'] as Map<String, dynamic>?;
    if (errors != null && errors.isNotEmpty) {
      final firstField = errors.values.first;
      final message = firstField is List ? firstField.first : firstField;
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    }

    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final error = data['error']?.toString();
    if (error != null && error.isNotEmpty) {
      return error;
    }

    return fallback;
  }
}
