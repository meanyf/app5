// lib/map/comment.dart

class Comment {
  final String id;
  final String activityId;
  final String userId;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as String,
    activityId: json['activity_id'] as String,
    userId: json['user_id'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
