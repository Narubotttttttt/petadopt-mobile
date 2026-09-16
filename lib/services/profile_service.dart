import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/user'),
          headers: ApiClient.headersWithToken(token),
        )
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AuthService.userKey, jsonEncode(user));
      return user;
    }
    return null;
  }

  static Future<Map<String, dynamic>> updateProfileName(String name) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/user/update-profile'),
          headers: ApiClient.headersWithToken(token),
          body: jsonEncode({'name': name}),
        )
        .timeout(ApiConfig.defaultTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['user'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AuthService.userKey, jsonEncode(data['user']));
    }
    return data;
  }

  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/user/update-avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.files.add(
      await http.MultipartFile.fromPath('avatar', imageFile.path),
    );

    final streamedResponse = await request.send().timeout(ApiConfig.uploadTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['user'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AuthService.userKey, jsonEncode(data['user']));
      return data;
    }

    throw Exception(data['message']?.toString() ?? 'Failed to upload profile picture.');
  }

  static Future<bool> updateAddress({
    required String address,
    String? city,
    String? province,
    String? phone,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/user/update-address'),
          headers: ApiClient.headersWithToken(token),
          body: jsonEncode({
            'address': address,
            'city': city,
            'province': province,
            'phone': phone,
          }),
        )
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      await fetchUserProfile();
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> updateUserSignature({
    required String signatureBase64,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/user/update-signature'),
          headers: ApiClient.headersWithToken(token),
          body: jsonEncode({
            'signature_data': signatureBase64,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      await fetchUserProfile();
      return data;
    }
    throw Exception(data['message']?.toString() ?? 'Failed to update digital signature.');
  }
}
