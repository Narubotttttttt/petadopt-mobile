import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.1.46:8000/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/register'),
          headers: _headers,
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': passwordConfirmation,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] as String);
      await prefs.setString(_userKey, jsonEncode(data['user']));
      await prefs.setString('last_active_timestamp', DateTime.now().toIso8601String());
      return data;
    }

    if (response.statusCode == 422) {
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstField = errors.values.first;
        final message = firstField is List ? firstField.first : firstField;
        throw Exception(message.toString());
      }
    }

    throw Exception(data['message']?.toString() ?? 'Registration failed. Please try again.');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] as String);
      await prefs.setString(_userKey, jsonEncode(data['user']));
      await prefs.setString('last_active_timestamp', DateTime.now().toIso8601String());
      return data;
    }

    if (response.statusCode == 401 || response.statusCode == 422) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
    }

    throw Exception('Login failed. Please check your credentials.');
  }

  static Future<Map<String, dynamic>> googleLogin({
    required String email,
    required String name,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/google-login'),
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'name': name,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] as String);
      await prefs.setString(_userKey, jsonEncode(data['user']));
      await prefs.setString('last_active_timestamp', DateTime.now().toIso8601String());
      return data;
    }

    throw Exception(data['message']?.toString() ?? 'Google sign-in failed. Please try again.');
  }

  static Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/send-email-otp'),
          headers: _headers,
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['message']?.toString() ?? 'Failed to send verification code.');
  }

  static Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/auth/verify-email-otp'),
          headers: _headers,
          body: jsonEncode({
            'email': email.trim(),
            'otp': otp.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return true;
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
          Uri.parse('$_baseUrl/auth/reset-password'),
          headers: _headers,
          body: jsonEncode({
            'email': email,
            'password': newPassword,
            'password_confirmation': confirmPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    }

    if (response.statusCode == 404 || response.statusCode == 422 || response.statusCode == 400) {
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstField = errors.values.first;
        final msg = firstField is List ? firstField.first : firstField;
        throw Exception(msg.toString());
      }
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
    }

    throw Exception(data['message']?.toString() ?? 'Password reset failed. Please try again.');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
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
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove('last_active_timestamp');
    await prefs.remove('user_full_address');
    await prefs.remove('user_city');
    await prefs.remove('user_barangay');

    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getPets({
    String? type,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
      queryParams['type'] = type.toLowerCase();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('$_baseUrl/pets').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    throw Exception('Failed to load pets from server.');
  }

  static Future<Map<String, dynamic>> getPetDetail(int id) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/pets/$id'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(json['data'] as Map);
    }

    throw Exception('Failed to load pet details.');
  }

  static Future<Map<String, dynamic>> submitAdoptionApplication({
    required Map<String, dynamic> data,
    String? validIdPath,
    String? certificatePath,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$_baseUrl/adoption-applications');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (validIdPath != null && validIdPath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('valid_id', validIdPath),
      );
    }

    if (certificatePath != null && certificatePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('barangay_certificate', certificatePath),
      );
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    final resData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201 || response.statusCode == 200) {
      return resData;
    }

    throw Exception(resData['message']?.toString() ?? 'Failed to submit adoption application.');
  }

  static Future<String?> getContractDownloadUrl(int id) async {
    final token = await getToken();
    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(Uri.parse('$_baseUrl/adoption-applications/$id/contract'), headers: headers).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['url'] as String?;
    }
    
    return null;
  }

  static Future<List<Map<String, dynamic>>> getMyApplications() async {
    final token = await getToken();
    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http
        .get(Uri.parse('$_baseUrl/my-applications'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    throw Exception('Failed to load applications.');
  }

  static Future<List<Map<String, dynamic>>> getVaccineReminders() async {
    final token = await getToken();
    if (token == null) return [];
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    final response = await http
        .get(Uri.parse('$_baseUrl/vaccine-reminders'), headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    return [];
  }

  static Future<void> saveFcmToken(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return;
      final headers = Map<String, String>.from(_headers);
      headers['Authorization'] = 'Bearer $token';

      await http.post(
        Uri.parse('$_baseUrl/save-fcm-token'),
        headers: headers,
        body: jsonEncode({'fcm_token': fcmToken}),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
