import 'dart:convert';
import 'package:http/http.dart' as http;
import 'activity.dart';

const String kBaseUrl = 'http://192.168.0.124:8000';

class ActivityService {
  static Future<List<Activity>> fetchActivities() async {
    final response = await http
        .get(Uri.parse('$kBaseUrl/activities/'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createActivity(Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('$kBaseUrl/activities/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
