import 'package:flutter/material.dart';
import 'meeting_request.dart';
import 'meeting_service.dart';

class MeetingSheet extends StatefulWidget {
  final String activityId;
  final String activityTitle;

  const MeetingSheet({
    super.key,
    required this.activityId,
    required this.activityTitle,
  });

  @override
  State<MeetingSheet> createState() => _MeetingSheetState();
}

class _MeetingSheetState extends State<MeetingSheet> {
  List<MeetingRequestWithUser> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await MeetingService.getActivityRequestsWithUsers(
      widget.activityId,
    );
    if (mounted)
      setState(() {
        _requests = requests;
        _loading = false;
      });
  }

  Future<void> _updateStatus(String requestId, String status) async {
    await MeetingService.updateRequest(requestId, status);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
          ? const Center(child: Text('Заявок пока нет'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final item = _requests[i];
                final req = item.request;
                final user = item.user;
                return ListTile(
                  leading: user?.avatarUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(user!.avatarUrl!),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user?.name ?? user?.phone ?? req.userId),
                  subtitle: Text(_statusLabel(req.status)),
                  trailing: req.status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed: () =>
                                  _updateStatus(req.id, 'approved'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () =>
                                  _updateStatus(req.id, 'rejected'),
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'pending' => 'На рассмотрении',
    'approved' => 'Одобрено',
    'rejected' => 'Отклонено',
    _ => status,
  };
}
