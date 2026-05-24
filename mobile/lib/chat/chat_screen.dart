// lib/chat/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../chat/comment.dart';
import '../chat/comment_service.dart';
import 'package:app5/user/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String activityId;
  final String activityTitle;

  const ChatScreen({
    super.key,
    required this.activityId,
    required this.activityTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = CommentService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');
    await _load();
  }

  Future<void> _load() async {
    try {
      final comments = await _service.getCommentsWithUsers(widget.activityId);
        for (final c in comments) {
        print(
          'comment ${c.id} userName=${c.userName} avatar=${c.userAvatarUrl}',
        );
      }
      if (mounted) {
        setState(() {
          _comments = comments;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
final comment = await _service.createComment(widget.activityId, text);
      _controller.clear();

      final userMap = await UserService.fetchBatch([comment.userId]);
      final enriched = comment.copyWith(
        userName: userMap[comment.userId]?.name ?? '',
        userAvatarUrl: userMap[comment.userId]?.avatarUrl,
      );

      if (mounted) {
        setState(() => _comments.add(enriched));
        _scrollToBottom();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка отправки')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.activityTitle, style: const TextStyle(fontSize: 16)),
            const Text(
              'Чат',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Text(
                      'Пока нет сообщений',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) => _ChatBubble(
                      comment: _comments[i],
                      isMe: _comments[i].userId == _currentUserId,
                    ),
                  ),
          ),
          _buildInput(scheme),
        ],
      ),
    );
  }

  Widget _buildInput(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            _sending
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xFF26A69A),
                    iconSize: 28,
                  ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Comment comment;
  final bool isMe;

  const _ChatBubble({required this.comment, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: comment.userAvatarUrl != null
                  ? NetworkImage(comment.userAvatarUrl!)
                  : null,
              child: comment.userAvatarUrl == null
                  ? Text(
                      comment.userName.isNotEmpty
                          ? comment.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF26A69A)
                    : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe && comment.userName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        comment.userName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  Text(
                    comment.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmt(comment.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
