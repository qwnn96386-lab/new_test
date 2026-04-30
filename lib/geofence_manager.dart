import 'package:geofence_service/geofence_service.dart';
import 'shop_model.dart';

class GeofenceManager {
  static final GeofenceManager _instance = GeofenceManager._internal();
  factory GeofenceManager() => _instance;
  GeofenceManager._internal();

  final _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    useActivityRecognition: true,
    allowMockLocations: false,
  );

  Function(String)? onStatusUpdate;

  Future<void> startGeofencing(List<Shop> shops) async {
    await _geofenceService.stop();
    _geofenceService.clearGeofenceList();

    for (var shop in shops) {
      _geofenceService.addGeofence(Geofence(
        id: shop.name,
        latitude: shop.lat,
        longitude: shop.lng,
        radius: [GeofenceRadius(id: 'r1', length: shop.radius)],
      ));
    }

    _geofenceService.addGeofenceStatusChangeListener((geofence, status, location) async {
      String msg = "雷達掃描中";
      if (status == GeofenceStatus.ENTER) msg = "進入：${geofence.id}";
      if (status == GeofenceStatus.EXIT) msg = "離開：${geofence.id}";
      onStatusUpdate?.call(msg);
    } as GeofenceStatusChanged);

    await _geofenceService.start().catchError((e) => print("雷達啟動失敗: $e"));
  }
}