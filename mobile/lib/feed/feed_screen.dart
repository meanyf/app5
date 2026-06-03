// lib/feed/feed_screen.dart

import 'package:flutter/material.dart';
import '../activity/activity.dart';
import '../activity/activity_service.dart';
import '../activity/activity_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Activity> _activities = [];
  bool _isLoading = true;
  String? _error;

  bool _filterMine = false;
  String? _filterType; // null, 'event', 'meeting'
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final activities = await ActivityService.fetchActivitiesWithAuthors(
        creatorId: _filterMine ? _currentUserId : null,
        activityType: _filterType,
      );
      if (mounted) setState(() => _activities = activities);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Лента'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Мои'),
                  selected: _filterMine,
                  onSelected: (v) {
                    setState(() => _filterMine = v);
                    _fetch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('События'),
                  selected: _filterType == 'event',
                  onSelected: (v) {
                    setState(() => _filterType = v ? 'event' : null);
                    _fetch();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Встречи'),
                  selected: _filterType == 'meeting',
                  onSelected: (v) {
                    setState(() => _filterType = v ? 'meeting' : null);
                    _fetch();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _fetch,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : _activities.isEmpty
          ? const Center(
              child: Text(
                'Пока нет активностей',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _activities.length,
                itemBuilder: (_, i) => _ActivityCard(activity: _activities[i]),
              ),
            ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = activity.media.where((m) => m.type == 'photo').firstOrNull;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ActivitySheet(activity: activity),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фото
            if (photo != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  photo.url,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Тип + дата
                  Row(
                    children: [
                      _TypeBadge(type: activity.type),
                      const Spacer(),
                      Text(
                        _fmtDate(activity.startsAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Название
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Описание
                  if (activity.description != null &&
                      activity.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      activity.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  // Адрес
                  if (activity.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      activity.address!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Автор
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: activity.authorAvatarUrl != null
                            ? NetworkImage(activity.authorAvatarUrl!)
                            : null,
                        child: activity.authorAvatarUrl == null
                            ? Text(
                                activity.authorName.isNotEmpty
                                    ? activity.authorName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activity.authorName.isNotEmpty
                            ? activity.authorName
                            : 'Пользователь',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Сегодня ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isEvent = type == 'event';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isEvent
            ? const Color(0xFF5C6BC0).withOpacity(0.12)
            : const Color(0xFF26A69A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isEvent ? 'Событие' : 'Встреча',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isEvent ? const Color(0xFF5C6BC0) : const Color(0xFF26A69A),
        ),
      ),
    );
  }
}
