import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'shop_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;
  Future<Database> get db async => _db ??= await _init();

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'geofence_radar.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute("CREATE TABLE shops(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, lat REAL, lng REAL, radius REAL)");
    });
  }

  Future<List<Shop>> getShops() async {
    final d = await db;
    final List<Map<String, dynamic>> maps = await d.query('shops');
    return maps.map((m) => Shop.fromMap(m)).toList();
  }

  Future<void> insertShop(Shop s) async {
    final d = await db;
    await d.insert('shops', s.toMap());
  }

  Future<void> deleteShop(int id) async {
    final d = await db;
    await d.delete('shops', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateShopRadius(int id, double radius) async {
    final d = await db;
    await d.update('shops', {'radius': radius}, where: 'id = ?', whereArgs: [id]);
  }
}