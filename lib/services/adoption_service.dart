import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class AdoptionService {
  static Future<Map<String, dynamic>> submitAdoptionApplication({
    required Map<String, dynamic> data,
    String? validIdPath,
    String? certificatePath,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/adoption-applications');
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

    final streamedResponse = await request.send().timeout(ApiConfig.uploadTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final resData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201 || response.statusCode == 200) {
      return resData;
    }

    throw Exception(resData['message']?.toString() ?? 'Failed to submit adoption application.');
  }

  static Future<String?> getContractDownloadUrl(int id) async {
    final token = await AuthService.getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/adoption-applications/$id/contract'),
          headers: ApiClient.headersWithToken(token),
        )
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['url'] as String?;
    }

    if (response.statusCode == 422 || response.statusCode == 400 || response.statusCode == 403) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? json['error'] ?? 'Please provide a signature first before downloading the contract.');
      } catch (e) {
        if (e is Exception) rethrow;
      }
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> getMyApplications() async {
    final token = await AuthService.getToken();

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/my-applications'),
          headers: ApiClient.headersWithToken(token),
        )
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    throw Exception('Failed to load applications.');
  }

  static Future<Map<String, dynamic>> signAdoptionContract({
    required int applicationId,
    String? signatureBase64,
    bool useSavedSignature = false,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/adoption-applications/$applicationId/sign'),
          headers: ApiClient.headersWithToken(token),
          body: jsonEncode({
            'signature_data': signatureBase64,
            if (useSavedSignature) 'use_saved_signature': true,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      await ProfileService.fetchUserProfile();
      return data;
    }
    throw Exception(data['message']?.toString() ?? 'Failed to sign adoption contract.');
  }
}
