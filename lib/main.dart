import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MapScreen());
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<MapObject> mapObjects = [
    PlacemarkMapObject(
      mapId: const MapObjectId('pin_1'),
      point: const Point(latitude: 59.9343, longitude: 30.3351),

      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromAssetImage('assets/pin.png'),
          scale: 1.0,
        ),
      ),
    ),
    PlacemarkMapObject(
      mapId: const MapObjectId('pin_2'),
      point: const Point(latitude: 59.94, longitude: 30.3351),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yandex Map')),
      body: YandexMap(
        mapObjects: mapObjects,
        onMapCreated: (controller) {
          controller.moveCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(
                target: Point(latitude: 59.9343, longitude: 30.3351),
                zoom: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}
