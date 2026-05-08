import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yandex_mapkit/yandex_mapkit.dart';

// ─── конфиг ───────────────────────────────────────────────────────────────────
const String kBaseUrl = 'http://192.168.0.124:8000'; // Android-эмулятор → localhost
const Duration kPollInterval = Duration(seconds: 20);

// ─── модель ───────────────────────────────────────────────────────────────────
class Activity {
  final String id;
  final String type; // "event" | "meeting"
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime startsAt;
  final DateTime expiresAt;

  const Activity({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.expiresAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        startsAt: DateTime.parse(json['starts_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}

// ─── app ──────────────────────────────────────────────────────────────────────
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activities',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C6BC0)),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

// ─── экран карты ──────────────────────────────────────────────────────────────
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _mapController;
  Timer? _pollTimer;

  List<Activity> _activities = [];
  bool _loading = true;
  String? _error;

  // ── жизненный цикл ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchActivities();
    _pollTimer = Timer.periodic(kPollInterval, (_) => _fetchActivities());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── получение данных ────────────────────────────────────────────────────────
  Future<void> _fetchActivities() async {
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl/activities/?limit=200'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
      final activities =
          json.map((e) => Activity.fromJson(e as Map<String, dynamic>)).toList();

      if (mounted) {
        setState(() {
          _activities = activities;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── пины на карте ───────────────────────────────────────────────────────────
  List<MapObject> get _mapObjects => _activities.map((activity) {
        return PlacemarkMapObject(
          mapId: MapObjectId('activity_${activity.id}'),
          point: Point(
            latitude: activity.latitude,
            longitude: activity.longitude,
          ),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage('assets/pin.png'),
              scale: activity.type == 'meeting' ? 1.4 : 1.2,
            ),
          ),
          onTap: (_, __) => _showActivitySheet(activity),
        );
      }).toList();

  // ── боттомшит с деталями ────────────────────────────────────────────────────
  void _showActivitySheet(Activity activity) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ActivitySheet(activity: activity),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YandexMap(
            mapObjects: _mapObjects,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(
                    target: Point(latitude: 55.7558, longitude: 37.6173),
                    zoom: 12,
                  ),
                ),
              );
            },
          ),

          // индикатор загрузки / ошибки
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _ErrorBanner(message: _error!, onRetry: _fetchActivities),

          // счётчик активностей
          if (!_loading && _error == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _ActivityCounter(count: _activities.length),
            ),
        ],
      ),

      // кнопка ручного обновления
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchActivities,
        tooltip: 'Обновить',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// ─── вспомогательные виджеты ──────────────────────────────────────────────────

class _ActivityCounter extends StatelessWidget {
  final int count;
  const _ActivityCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count активностей',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ошибка: $message',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Повтор'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivitySheet extends StatelessWidget {
  final Activity activity;
  const _ActivitySheet({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isEvent = activity.type == 'event';
    final color =
        isEvent ? const Color(0xFF5C6BC0) : const Color(0xFF26A69A);
    final label = isEvent ? 'Событие' : 'Встреча';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          // тип + заголовок
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (activity.description != null) ...[
            const SizedBox(height: 10),
            Text(
              activity.description!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],

          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.schedule,
            text: _formatDateTime(activity.startsAt),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.timer_off_outlined,
            text: 'До ${_formatDateTime(activity.expiresAt)}',
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }
}