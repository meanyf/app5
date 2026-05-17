// lib/map/comment_service.dart

import 'dart:convert';
import 'comment.dart';
import 'package:app5/core/api_client.dart';

final _client = ApiClient();

class CommentService {
  static final CommentService _instance = CommentService._();
  factory CommentService() => _instance;
  CommentService._();
  // static const String baseUrl = 'http://192.168.0.124:8001';

  Future<List<Comment>> getComments(String activityId) async {
    final response = await _client
            .get('/comments/$activityId')
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
    final response = await _client
            .post('/comments/$activityId', {'text': text})
            .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw Exception('HTTP ${response.statusCode}');
    }

    return Comment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
