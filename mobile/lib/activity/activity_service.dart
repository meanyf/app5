// lib/map/activity_service.dart

import 'dart:convert';
import 'activity.dart';
import 'package:app5/core/api_client.dart';
import 'package:app5/user/user_service.dart';

final _client = ApiClient();

// const String kBaseUrl = 'http://192.168.0.124:8000';
// const String kMediaUrl = 'http://192.168.0.124:8002'; // media-service

class ActivityService {
  static Future<List<Activity>> fetchActivities({
    String? creatorId,
    String? activityType,
  }) async {
    final params = <String, String>{};
    if (creatorId != null) params['creator_id'] = creatorId;
    if (activityType != null) params['activity_type'] = activityType;

    final query = params.isEmpty
        ? ''
        : '?${Uri(queryParameters: params).query}';

    final response = await _client
        .get('/activities/$query')
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  
static Future<List<Activity>> fetchActivitiesWithAuthors({
    String? creatorId,
    String? activityType,
  }) async {
    final activities = await fetchActivities(
      creatorId: creatorId,
      activityType: activityType,
    );

    final authorIds = activities.map((a) => a.creatorId).toSet().toList();
    final userMap = await UserService.fetchBatch(authorIds);

    return activities
        .map(
          (a) => a.copyWith(
            authorName:
                userMap[a.creatorId]?.name ??
                userMap[a.creatorId]?.phone ??
                'Пользователь',
            authorAvatarUrl: userMap[a.creatorId]?.avatarUrl,
          ),
        )
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
}
