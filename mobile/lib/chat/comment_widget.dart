import 'package:flutter/material.dart';
import 'comment.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentTile({
    required this.comment,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEEEEEE),
            backgroundImage: comment.userAvatarUrl != null
                ? NetworkImage(comment.userAvatarUrl!)
                : null,
            child: comment.userAvatarUrl == null
                ? const Icon(Icons.person, size: 18, color: Color(0xFF9E9E9E))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Text(
                          comment.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 4),
                      _OptionsButton(onEdit: onEdit, onDelete: onDelete),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(comment.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _OptionsButton extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _OptionsButton({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: PopupMenuButton<_CommentAction>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFFBDBDBD)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (action) {
          if (action == _CommentAction.edit) onEdit?.call();
          if (action == _CommentAction.delete) onDelete?.call();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: _CommentAction.edit,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: Color(0xFF616161)),
                SizedBox(width: 10),
                Text('Редактировать', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: _CommentAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  'Удалить',
                  style: TextStyle(fontSize: 14, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CommentAction { edit, delete }
