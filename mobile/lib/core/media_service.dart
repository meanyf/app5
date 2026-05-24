import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:app5/core/api_client.dart';
import 'dart:convert';

class MediaItem {
  final String url;
  final String type; // "photo" | "video"

  const MediaItem({required this.url, required this.type});

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      MediaItem(url: json['url'] as String, type: json['type'] as String);

  Map<String, dynamic> toJson() => {'url': url, 'type': type};
}

class MediaService {
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