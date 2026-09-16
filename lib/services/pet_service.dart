import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class PetService {
  static Future<List<Map<String, dynamic>>> getPets({
    String? type,
    String? search,
  }) async {
    final token = await AuthService.getToken();
    final queryParams = <String, String>{};
    if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
      queryParams['type'] = type.toLowerCase();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/pets').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http
        .get(uri, headers: ApiClient.headersWithToken(token))
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['data'] as List<dynamic>;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    throw Exception('Failed to load pets from server.');
  }

  static Future<Map<String, dynamic>> getPetDetail(int id) async {
    final token = await AuthService.getToken();

    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/pets/$id'), headers: ApiClient.headersWithToken(token))
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Map<String, dynamic>.from(json['data'] as Map);
    }

    throw Exception('Failed to load pet details.');
  }
}
