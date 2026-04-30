class Shop {
  final int? id;
  final String name;
  final double lat;
  final double lng;
  double radius;

  Shop({this.id, required this.name, required this.lat, required this.lng, this.radius = 100.0});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name, 'lat': lat, 'lng': lng, 'radius': radius,
  };

  factory Shop.fromMap(Map<String, dynamic> m) => Shop(
    id: m['id'] as int?,
    name: m['name'] as String,
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    radius: (m['radius'] as num?)?.toDouble() ?? 100.0,
  );
}