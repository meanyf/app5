import 'dart:convert';
import '../core/api_client.dart';
import 'user.dart';
import 'package:http/http.dart' as http;

class UserService {
  static final _client = ApiClient();


static Future<http.Response> updateFcmToken(String token) async {
    return await _client.patch('/users/me', {'fcm_token': token});
  }

  static Future<Map<String, UserProfile>> fetchBatch(List<String> ids) async {
    if (ids.isEmpty) return {};
    final response = await _client.post('/users/batch', {'ids': ids});
    print(
      'fetchBatch ids=$ids status=${response.statusCode} body=${response.body}',
    );
    if (response.statusCode != 200) return {};
    final List list = jsonDecode(response.body);
    return {
      for (final json in list)
        (json['id'] as String): UserProfile.fromJson(json),
    };
  }

  static void invalidate(String userId) {} // оставь чтобы не ломать вызовы
}
