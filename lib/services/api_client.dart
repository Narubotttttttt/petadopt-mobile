class ApiClient {
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> headersWithToken(String? token) => {
    ...defaultHeaders,
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

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
