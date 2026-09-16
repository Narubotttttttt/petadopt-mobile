import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_client.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  /// Saves user details to SharedPreferences for quick offline access
  static Future<void> _cacheUserData(SharedPreferences prefs, Map<String, dynamic>? userMap) async {
    if (userMap == null) return;
    await prefs.setString(userKey, jsonEncode(userMap));
    final userId = userMap['id'];
    if (userId != null) {
      final addr = userMap['address']?.toString();
      if (addr != null && addr.trim().isNotEmpty) {
        await prefs.setString('user_${userId}_full_address', addr.trim());
      }
      final phone = userMap['phone']?.toString();
      if (phone != null && phone.trim().isNotEmpty) {
        await prefs.setString('user_${userId}_phone', phone.trim());
      }
      final city = userMap['city']?.toString();
      if (city != null && city.trim().isNotEmpty) {
        await prefs.setString('user_${userId}_city', city.trim());
      }
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: ApiClient.defaultHeaders,
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(ApiConfig.defaultTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, data['token'] as String);
      await prefs.setString('last_active_timestamp', DateTime.now().toIso8601String());
      await _cacheUserData(prefs, data['user'] as Map<String, dynamic>?);
      return data;
    }

    if (response.statusCode == 422) {
      throw Exception(ApiClient.extractErrorMessage(data));
    }

    throw Exception(data['message']?.toString() ?? 'Registration failed. Please try again.');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/login'),
          headers: ApiClient.defaultHeaders,
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(ApiConfig.defaultTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      if (data['user'] != null && data['user']['role'] != 'adopter') {
        throw Exception('Admin accounts cannot log in to the mobile app. Please use the Web Admin Portal.');
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, data['token'] as String);
      await prefs.setString('last_active_timestamp', DateTime.now().toIso8601String());
      await _cacheUserData(prefs, data['user'] as Map<String, dynamic>?);
      return data;
    }

    if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 422) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
    }

    throw Exception('Login failed. Please check your credentials.');
  }

  static Future<Map<String, dynamic>> checkEmailAvailability(String email) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/check-email'),
          headers: ApiClient.defaultHeaders,
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(ApiConfig.defaultTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    }

    if (response.statusCode == 422) {
      throw Exception(ApiClient.extractErrorMessage(data, fallback: 'Failed to check email availability.'));
    }

    throw Exception(data['message']?.toString() ?? 'Failed to check email availability.');
  }

  static Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/send-email-otp'),
          headers: ApiClient.defaultHeaders,
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(ApiConfig.defaultTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    if (response.statusCode == 422) {
      throw Exception(ApiClient.extractErrorMessage(data, fallback: 'Failed to send verification code.'));
    }

    throw Exception(data['message']?.toString() ?? 'Failed to send verification code.');
  }

  static Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/verify-email-otp'),
          headers: ApiClient.defaultHeaders,
          body: jsonEncode({
            'email': email.trim(),
            'otp': otp.trim(),
          }),
        )
        .timeout(ApiConfig.defaultTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return true;
    }

    if (response.statusCode == 422) {
      throw Exception(ApiClient.extractErrorMessage(data, fallback: 'Invalid or expired verification code.'));
    }

    throw Exception(data['message']?.toString() ?? 'Invalid or expired verification code.');
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
          headers: ApiClient.defaultHeaders,
          body: jsonEncode({
            'email': email,
            'password': newPassword,
            'password_confirmation': confirmPassword,
          }),
        )
        .timeout(ApiConfig.defaultTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    }

    if (response.statusCode == 404 || response.statusCode == 422 || response.statusCode == 400) {
      throw Exception(ApiClient.extractErrorMessage(data, fallback: 'Password reset failed. Please try again.'));
    }

    throw Exception(data['message']?.toString() ?? 'Password reset failed. Please try again.');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/user'), headers: ApiClient.headersWithToken(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await _cacheUserData(prefs, data);
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await clearSession();
        return null;
      }
    } catch (_) {}
    return getUser();
  }

  static Future<void> updateLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_active_timestamp', DateTime.now().toIso8601String());
  }

  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString('last_active_timestamp');
    if (lastActiveStr == null) return false;
    final lastActive = DateTime.tryParse(lastActiveStr);
    if (lastActive == null) return false;
    final difference = DateTime.now().difference(lastActive);
    return difference.inDays >= 7;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
    await prefs.remove('last_active_timestamp');
    await prefs.remove('user_full_address');
    await prefs.remove('user_city');
    await prefs.remove('user_barangay');
  }

  static Future<void> saveFcmToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/save-fcm-token'),
        headers: ApiClient.headersWithToken(token),
        body: jsonEncode({'fcm_token': fcmToken}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
