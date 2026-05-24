// lib/map/comment_service.dart

import 'dart:convert';
import 'comment.dart';
import 'package:app5/core/api_client.dart';
import 'package:app5/user/user_service.dart';

final _client = ApiClient();

class CommentService {
  static final CommentService _instance = CommentService._();
  factory CommentService() => _instance;
  CommentService._();
  // static const String baseUrl = 'http://192.168.0.124:8001';

  Future<List<Comment>> getCommentsWithUsers(String activityId) async {
    final comments = await getComments(activityId);
    final userIds = comments.map((c) => c.userId).toSet().toList();
    final userMap = await UserService.fetchBatch(userIds);

return comments
        .map(
          (c) => c.copyWith(
            userName:
                userMap[c.userId]?.name ??
                userMap[c.userId]?.phone ??
                c.userId.substring(0, 8),
            userAvatarUrl: userMap[c.userId]?.avatarUrl,
          ),
        )
        .toList();
  }
  
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
