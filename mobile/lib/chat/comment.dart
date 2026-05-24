class Comment {
  final String id;
  final String activityId;
  final String userId;
  final String userName;
  final String? userAvatarUrl; // добавили
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.activityId,
    required this.userId,
    this.userName = '',
    this.userAvatarUrl, // добавили
    required this.text,
    required this.createdAt,
  });

  Comment copyWith({String? userName, String? userAvatarUrl}) => Comment(
    id: id,
    activityId: activityId,
    userId: userId,
    userName: userName ?? this.userName,
    userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl, // добавили
    text: text,
    createdAt: createdAt,
  );

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as String,
    activityId: json['activity_id'] as String,
    userId: json['user_id'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
