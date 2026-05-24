import 'dart:convert';
import 'package:app5/core/api_client.dart';
import 'meeting_request.dart';
import '../user/user_service.dart';

class MeetingService {
  static final _client = ApiClient();

  static Future<MeetingRequest> createRequest(String activityId) async {
    final response = await _client.post('/meetings/', {
      'activity_id': activityId,
    });
    if (response.statusCode != 200)
      throw Exception('HTTP ${response.statusCode}');
    return MeetingRequest.fromJson(jsonDecode(response.body));
  }

  static Future<MeetingRequest?> getMyRequest(String activityId) async {
    final response = await _client.get('/meetings/my');
    if (response.statusCode != 200) return null;
    final List list = jsonDecode(response.body);
    final all = list.map((e) => MeetingRequest.fromJson(e)).toList();
    return all.where((r) => r.activityId == activityId).firstOrNull;
  }

  static Future<List<MeetingRequest>> getActivityRequests(
    String activityId,
  ) async {
    final response = await _client.get('/meetings/activity/$activityId');
    if (response.statusCode != 200) return [];
    final List list = jsonDecode(response.body);
    return list.map((e) => MeetingRequest.fromJson(e)).toList();
  }

  static Future<void> updateRequest(String requestId, String status) async {
    await _client.patch('/meetings/$requestId', {'status': status});
  }

  static Future<List<MeetingRequestWithUser>> getActivityRequestsWithUsers(
    String activityId,
  ) async {
    final requests = await getActivityRequests(activityId);
    if (requests.isEmpty) return [];

    final userMap = await UserService.fetchBatch(
      requests.map((r) => r.userId).toSet().toList(),
    );

    return requests
        .map((r) => MeetingRequestWithUser(request: r, user: userMap[r.userId]))
        .toList();
  }
}
