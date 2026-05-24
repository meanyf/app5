import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../activity/activity.dart';
import '../activity/activity_service.dart';
import '../activity/activity_widgets.dart';
import '../activity/activity_sheet.dart';
import 'create_activity_sheet.dart';
import 'package:app5/profile/profile_screen.dart';
import '../feed/feed_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'address_search_sheet.dart';

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

  bool _filterMine = false;
  String? _filterType;
  String? _currentUserId;

@override
  void initState() {
    super.initState();
    _loadUser();
    _requestLocation();
    _fetchActivities();
    _pollTimer = Timer.periodic(kPollInterval, (_) => _fetchActivities());
  }

Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentUserId = prefs.getString('user_id'));
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    debugPrint('Location permission status: $status');

  }

  Future<String?> _getAddress(Point point) async {
    final (_, result) = await YandexSearch.searchByPoint(
      point: point,
      zoom: 16,
      searchOptions: const SearchOptions(
        searchType: SearchType.geo,
        resultPageSize: 1,
      ),
    );
    final searchResult = await result;
    if (searchResult.error != null) return null;
    return searchResult.items?.firstOrNull?.name;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    try {
      final activities = await ActivityService.fetchActivitiesWithAuthors(
              creatorId: _filterMine ? _currentUserId : null,
              activityType: _filterType,
            );
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


void _onSearchAddress() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => AddressSearchSheet(
          onAddressSelected: (query) async {
            await _searchAndCreate(query);
          },
        ),
      ),
    );
  }

Future<void> _searchAndCreate(String query) async {
  if (query.isEmpty) return;

  final (_, result) = await YandexSearch.searchByText(
    searchText: query,
    geometry: Geometry.fromBoundingBox(const BoundingBox(
      southWest: Point(latitude: -90, longitude: -180),
      northEast: Point(latitude: 90, longitude: 180),
    )),
    searchOptions: const SearchOptions(
      searchType: SearchType.geo,
      resultPageSize: 1,
    ),
  );

  final searchResult = await result;
  if (searchResult.error != null || searchResult.items == null || searchResult.items!.isEmpty) return;

  final item = searchResult.items!.first;
  final point = item.geometry.first.point;
  if (point == null) return;

  await _mapController?.moveCamera(
    CameraUpdate.newCameraPosition(CameraPosition(target: point, zoom: 15)),
    animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.5),
  );

  if (!mounted) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => CreateActivitySheet(
      latitude: point.latitude,
      longitude: point.longitude,
      address: item.name,
      onSubmit: _createActivity,
    ),
  );
}

Future<void> _moveToUser() async {
    final userPosition = await _mapController?.getUserCameraPosition();
    if (userPosition == null) return;
    await _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userPosition.target,
          zoom: 15, // игнорируем userPosition.zoom
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.5,
      ),
    );
  }

 void _onMapLongTap(Point point) async {
    final address = await _getAddress(point);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateActivitySheet(
        latitude: point.latitude,
        longitude: point.longitude,
        address: address, // добавь этот параметр
        onSubmit: _createActivity,
      ),
    );
  }

  void _showActivitySheet(Activity activity) {
    debugPrint('Activity id: ${activity.id}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // добавить
      backgroundColor: Colors.transparent, // добавить
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
        : 'assets/event.png';

    return PlacemarkMapObject(
      mapId: MapObjectId('activity_${activity.id}'),
      point: Point(latitude: activity.latitude, longitude: activity.longitude),
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage(iconAsset),
          scale: activity.type == 'meeting' ? 0.2 : 0.2,
        ),
      ),
      onTap: (_, __) => _showActivitySheet(activity),
    );
  }).toList();

Widget _buildChip(
    String label,
    bool selected,
    ValueChanged<bool> onSelected,
  ) {
    return RawChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      onSelected: onSelected,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF5C6BC0).withOpacity(0.2),
      visualDensity: VisualDensity.compact,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
         YandexMap(
            mapObjects: _mapObjects,
            onUserLocationAdded: (UserLocationView view) async {
              return view.copyWith(
                pin: view.pin.copyWith(
                  icon: PlacemarkIcon.single(
                    PlacemarkIconStyle(
                      image: BitmapDescriptor.fromAssetImage('assets/pin.png'),
                      scale: 0.2,
                    ),
                  ),
                ),
                accuracyCircle: view.accuracyCircle.copyWith(
                  fillColor: const Color(0xFF5C6BC0).withOpacity(0.15),
                  strokeColor: const Color(0xFF5C6BC0),
                  strokeWidth: 1.0,
                ),
              );
            },
onMapCreated: (controller) async {
              _mapController = controller;
              await controller.toggleUserLayer(
                visible: true,
                autoZoomEnabled: true,
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
              left: 16,
              bottom: 100,
              child: FloatingActionButton(
                mini: true,
                onPressed: _moveToUser,
                child: const Icon(Icons.my_location),
              ),
            ),

          Positioned(
            left: 16,
            bottom: 156,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                print('BUTTON TAPPED');
                _onSearchAddress();
              },              child: const Icon(Icons.search),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Color(0xFF5C6BC0),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildChip('Мои', _filterMine, (v) {
                  setState(() => _filterMine = v);
                  _fetchActivities();
                }),
                const SizedBox(height: 4),
                _buildChip('События', _filterType == 'event', (v) {
                  setState(() => _filterType = v ? 'event' : null);
                  _fetchActivities();
                }),
                const SizedBox(height: 4),
                _buildChip('Встречи', _filterType == 'meeting', (v) {
                  setState(() => _filterType = v ? 'meeting' : null);
                  _fetchActivities();
                }),
              ],
            ),
          ),

// Кнопка ленты — правый верхний угол
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FeedScreen())),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.dynamic_feed,
                  size: 20,
                  color: Color(0xFF5C6BC0),
                ),
              ),
            ),
          ),

          // Счётчик активностей — чуть ниже
          Positioned(
            top: MediaQuery.of(context).padding.top + 52,
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
