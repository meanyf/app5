// lib/map/create_activity_sheet.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'activity.dart';
import 'activity_service.dart';
import 'activity_widgets.dart';
import 'package:video_player/video_player.dart';

class CreateActivitySheet extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

final String? address;

  const CreateActivitySheet({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.onSubmit,
  });

  @override
  State<CreateActivitySheet> createState() => _CreateActivitySheetState();
}

class _CreateActivitySheetState extends State<CreateActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  String _type = 'event';
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 3));
  bool _submitting = false;
  String? _submitError;
  

  // медиа
  final List<File> _selectedFiles = [];
  final List<MediaItem> _uploadedMedia = [];
  bool _uploadingMedia = false;
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Set<int> _videoIndices = {};


// ── dispose (замени существующий) ─────────────────────────────────────────────
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _maxParticipantsController.dispose();
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── метод выбора медиа (замени _pickImage) ────────────────────────────────────
Future<void> _pickMedia() async {
  final picker = ImagePicker();
  final picked = await picker.pickMedia();
  if (picked == null) return;
 
  final file = File(picked.path);
  final isVideo = picked.mimeType?.startsWith('video') == true ||
      picked.path.endsWith('.mp4') ||
      picked.path.endsWith('.mov');
 
  final index = _selectedFiles.length;
 
  setState(() {
    _selectedFiles.add(file);
    _uploadingMedia = true;
  });
 
  // инициализируем контроллер для видео
  if (isVideo) {
    setState(() => _videoIndices.add(index)); // ← добавь эту строку

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    if (mounted) {
      setState(() => _videoControllers[index] = controller);
    }
  }
 
  try {
    final item = await ActivityService.uploadMedia(file);
    if (mounted) setState(() => _uploadedMedia.add(item));
  } catch (e) {
    if (mounted) {
      setState(() {
        _selectedFiles.removeAt(index);
        _videoControllers[index]?.dispose();
        _videoControllers.remove(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _uploadingMedia = false);
  }
}
 
// ── удаление медиа (замени _removeMedia) ──────────────────────────────────────
void _removeMedia(int index) {
    _videoControllers[index]?.dispose();
    setState(() {
      _selectedFiles.removeAt(index);
      _uploadedMedia.removeAt(index);
      _videoIndices.remove(index);
      // пересобираем индексы видео
      final updatedIndices = _videoIndices
          .map((i) => i > index ? i - 1 : i)
          .toSet();
      _videoIndices
        ..clear()
        ..addAll(updatedIndices);
      // контроллеры как раньше
      final updated = <int, VideoPlayerController>{};
      _videoControllers.forEach((k, v) {
        if (k < index) updated[k] = v;
        if (k > index) updated[k - 1] = v;
      });
      _videoControllers
        ..clear()
        ..addAll(updated);
    });
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;
    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiresAt.isBefore(_startsAt)) {
      setState(() => _submitError = 'Дата окончания раньше даты начала');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final body = <String, dynamic>{
        'type': _type,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'starts_at': _startsAt.toUtc().toIso8601String(),
        'expires_at': _expiresAt.toUtc().toIso8601String(),
        'media': _uploadedMedia.map((m) => m.toJson()).toList(),
      };

      if (_type == 'meeting' &&
          _maxParticipantsController.text.trim().isNotEmpty) {
        body['max_participants'] = int.parse(
          _maxParticipantsController.text.trim(),
        );
      }

      await widget.onSubmit(body);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _submitError = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const colorEvent = Color(0xFF5C6BC0);
    const colorMeeting = Color(0xFF26A69A);
    final activeColor = _type == 'event' ? colorEvent : colorMeeting;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? MediaQuery.of(context).viewInsets.bottom + 16
            : MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Новая метка',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
Text(
                '${widget.latitude.toStringAsFixed(5)}, '
                '${widget.longitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              if (widget.address != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.address!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 20),

              // тип
              Row(
                children: [
                  TypeChip(
                    label: 'Событие',
                    selected: _type == 'event',
                    color: colorEvent,
                    onTap: () => setState(() => _type = 'event'),
                  ),
                  const SizedBox(width: 10),
                  TypeChip(
                    label: 'Встреча',
                    selected: _type == 'meeting',
                    color: colorMeeting,
                    onTap: () => setState(() => _type = 'meeting'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // название
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Название *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeColor, width: 2),
                  ),
                ),
                maxLength: 100,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Введите название' : null,
              ),
              const SizedBox(height: 12),

              // описание
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeColor, width: 2),
                  ),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 12),

              // макс. участников — только для встреч
              if (_type == 'meeting') ...[
                TextFormField(
                  controller: _maxParticipantsController,
                  decoration: InputDecoration(
                    labelText: 'Макс. участников',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: activeColor, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 2) return 'Минимум 2 участника';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              // ── медиа ──────────────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Медиа',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  if (_uploadingMedia)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_selectedFiles.length < 5)
                    TextButton.icon(
                      onPressed: _pickMedia,
                      icon: Icon(
                        Icons.perm_media,
                        color: activeColor,
                        size: 18,
                      ),
                      label: Text(
                        'Добавить',
                        style: TextStyle(color: activeColor, fontSize: 13),
                      ),
                    ),
                ],
              ),

              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                    final isVideo = _videoIndices.contains(i);
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: isVideo
                                ? SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        VideoPlayer(_videoControllers[i]!),
                                        const Center(
                                          child: Icon(
                                            Icons.play_circle_outline,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.file(
                                    _selectedFiles[i],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeMedia(i),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // даты
              Row(
                children: [
                  Expanded(
                    child: DateTimeField(
                      label: 'Начало',
                      value: _startsAt,
                      color: activeColor,
                      onTap: () async {
                        final dt = await _pickDateTime(_startsAt);
                        if (dt != null) setState(() => _startsAt = dt);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DateTimeField(
                      label: 'Окончание',
                      value: _expiresAt,
                      color: activeColor,
                      onTap: () async {
                        final dt = await _pickDateTime(_expiresAt);
                        if (dt != null) setState(() => _expiresAt = dt);
                      },
                    ),
                  ),
                ],
              ),

              // ошибка
              if (_submitError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _submitError!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // кнопка
              FilledButton(
                onPressed: (_submitting || _uploadingMedia) ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: activeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Создать метку',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
