// lib/map/activity_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'activity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app5/core/api_client.dart';

final _client = ApiClient();

// const String kBaseUrl = 'http://192.168.0.124:8000';
// const String kMediaUrl = 'http://192.168.0.124:8002'; // media-service

class ActivityService {
  static Future<List<Activity>> fetchActivities() async {
    final response = await _client
        .get('/activities/')
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
    final response = await _client
            .post('/activities/', body)
            .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  /// Загружает файл в media-service, возвращает {url, type}
  static Future<MediaItem> uploadMedia(File file) async {
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final parts = mimeType.split('/');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/media/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType(parts[0], parts[1]),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Ошибка загрузки медиа: HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MediaItem(url: json['url'] as String, type: json['type'] as String);
    }
}
