import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class HealthService {
  static Future<Map<String, dynamic>> submitHealthUpdate({
    required int applicationId,
    required File photo,
    required String healthStatus,
    double? weight,
    String? notes,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/health-updates');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields['application_id'] = applicationId.toString();
    request.fields['health_status'] = healthStatus;
    if (weight != null) {
      request.fields['weight'] = weight.toString();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      request.fields['notes'] = notes.trim();
    }
    request.files.add(
      await http.MultipartFile.fromPath('photo', photo.path),
    );

    final streamedResponse = await request.send().timeout(ApiConfig.uploadTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201 && data['success'] == true) {
      return data;
    }

    throw Exception(data['message']?.toString() ?? 'Failed to submit health check-in.');
  }

  static Future<List<Map<String, dynamic>>> getMyHealthUpdates({int? applicationId}) async {
    final token = await AuthService.getToken();
    var url = '${ApiConfig.baseUrl}/my-health-updates';
    if (applicationId != null) {
      url += '?application_id=$applicationId';
    }

    final response = await http
        .get(Uri.parse(url), headers: ApiClient.headersWithToken(token))
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> getVaccineReminders() async {
    final token = await AuthService.getToken();
    if (token == null) return [];

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/vaccine-reminders'),
          headers: ApiClient.headersWithToken(token),
        )
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    return [];
  }
}
