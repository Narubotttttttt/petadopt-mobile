import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class RecommendationService {
  static Future<List<Map<String, dynamic>>> getRecommendations({
    Map<String, dynamic>? profile,
  }) async {
    final token = await AuthService.getToken();

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/recommendations/match'),
          headers: ApiClient.headersWithToken(token),
          body: jsonEncode(profile ?? {}),
        )
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['recommendations'] as List<dynamic>? ?? [];
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    return [];
  }

  static Future<Map<String, dynamic>?> getSavedPreferences() async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/recommendations/my-preferences'),
            headers: ApiClient.headersWithToken(token),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['preferences'] != null) {
          return Map<String, dynamic>.from(json['preferences'] as Map);
        }
      }
    } catch (_) {}

    return null;
  }
}
