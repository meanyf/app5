import '../user/user.dart';

class MeetingRequest {
  final String id;
  final String activityId;
  final String userId;
  final String status; // pending, approved, rejected
  final DateTime createdAt;

  const MeetingRequest({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  factory MeetingRequest.fromJson(Map<String, dynamic> json) => MeetingRequest(
    id: json['id'] as String,
    activityId: json['activity_id'] as String,
    userId: json['user_id'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class MeetingRequestWithUser {
  final MeetingRequest request;
  final UserProfile? user;

  const MeetingRequestWithUser({required this.request, this.user});
}
