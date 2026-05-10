// lib/map/comment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'comment.dart';

class CommentService {
  static final CommentService _instance = CommentService._();
  factory CommentService() => _instance;
  CommentService._();
  static const String baseUrl = 'http://192.168.0.124:8001';

  Future<List<Comment>> getComments(String activityId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/comments/$activityId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> createComment(String activityId, String text) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/comments/$activityId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
