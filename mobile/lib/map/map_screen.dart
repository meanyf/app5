import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'activity.dart';
import 'activity_service.dart';
import 'activity_widgets.dart';
import 'activity_sheet.dart';
import 'create_activity_sheet.dart';

const Duration kPollInterval = Duration(seconds: 20);

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

  Future<void> _fetchActivities() async {
    try {
      final activities = await ActivityService.fetchActivities();
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

  Future<void> _createActivity(Map<String, dynamic> body) async {
    await ActivityService.createActivity(body);
    await _fetchActivities();
  }

  void _onMapLongTap(Point point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateActivitySheet(
        latitude: point.latitude,
        longitude: point.longitude,
        onSubmit: _createActivity,
      ),
    );
  }

  void _showActivitySheet(Activity activity) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ActivitySheet(activity: activity),
    );
  }

List<MapObject> get _mapObjects => _activities.map((activity) {
    final String iconAsset = activity.type == 'meeting'
        ? 'assets/meeting.png'
        : 'assets/pin.png';

    return PlacemarkMapObject(
      mapId: MapObjectId('activity_${activity.id}'),
      point: Point(latitude: activity.latitude, longitude: activity.longitude),
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage(iconAsset),
          scale: activity.type == 'meeting' ? 0.4 : 0.2,
        ),
      ),
      onTap: (_, __) => _showActivitySheet(activity),
    );
  }).toList();

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
            onMapLongTap: _onMapLongTap,
          ),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ErrorBanner(message: _error!, onRetry: _fetchActivities),

          if (!_loading && _error == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: ActivityCounter(count: _activities.length),
            ),

          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 90,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _activities.isEmpty && !_loading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Удерживайте карту, чтобы создать метку',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: FloatingActionButton(
          onPressed: _fetchActivities,
          tooltip: 'Обновить',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
