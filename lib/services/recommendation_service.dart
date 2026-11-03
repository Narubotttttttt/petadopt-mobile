import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';

class RecommendationService {
  static int adoptedCount = 0;
  static int maxPetsAllowed = 3;
  static bool maxLimitReached = false;

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
      adoptedCount = json['adopted_count'] is int ? json['adopted_count'] as int : 0;
      maxPetsAllowed = json['max_pets_allowed'] is int ? json['max_pets_allowed'] as int : 3;
      maxLimitReached = json['max_limit_reached'] == true || adoptedCount >= maxPetsAllowed;

      final list = json['recommendations'] as List<dynamic>? ?? [];
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else if (response.statusCode == 403) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(json['message'] ?? 'Your compatibility quiz has already been submitted and cannot be changed.');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Your compatibility quiz has already been submitted and cannot be changed.');
      }
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
        adoptedCount = json['adopted_count'] is int ? json['adopted_count'] as int : 0;
        maxPetsAllowed = json['max_pets_allowed'] is int ? json['max_pets_allowed'] as int : 3;
        maxLimitReached = adoptedCount >= maxPetsAllowed;

        if (json['preferences'] != null) {
          final map = Map<String, dynamic>.from(json['preferences'] as Map);
          map['is_locked'] = json['is_locked'] ?? true;
          map['can_retake'] = json['can_retake'] ?? false;
          map['retake_status'] = json['retake_status'] ?? 'none';
          map['days_remaining'] = json['days_remaining'] ?? 0;
          map['next_retake_date'] = json['next_retake_date'];
          map['revision_count'] = json['revision_count'] ?? 0;
          map['adopted_count'] = adoptedCount;
          map['max_pets_allowed'] = maxPetsAllowed;
          map['max_limit_reached'] = maxLimitReached;
          return map;
        }
      }
    } catch (_) {}

    return null;
  }
}
