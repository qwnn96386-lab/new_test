import 'package:flutter/material.dart';
import 'shop_model.dart';
import 'db_helper.dart';
import 'geofence_manager.dart';

void main() => runApp(const MaterialApp(home: ShopRadarScreen(), debugShowCheckedModeBanner: false));

class ShopRadarScreen extends StatefulWidget {
  const ShopRadarScreen({super.key});
  @override
  State<ShopRadarScreen> createState() => _ShopRadarScreenState();
}

class _ShopRadarScreenState extends State<ShopRadarScreen> {
  List<Shop> shops = [];
  int selectedIndex = 0;
  String statusText = "初始化中...";

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // 刷新資料並重啟雷達
  void _refreshData() async {
    final data = await DBHelper().getShops();
    setState(() {
      shops = data;
      if (selectedIndex >= data.length && data.isNotEmpty) {
        selectedIndex = data.length - 1;
      }
    });

    GeofenceManager().onStatusUpdate = (msg) => setState(() => statusText = msg);
    if (data.isNotEmpty) {
      GeofenceManager().startGeofencing(data);
    } else {
      setState(() => statusText = "尚未新增店家");
    }
  }

  // 彈出新增對話框
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("新增監測店家"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "店家名稱")),
            TextField(controller: latCtrl, decoration: const InputDecoration(labelText: "緯度 (Lat)"), keyboardType: TextInputType.number),
            TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: "經度 (Lng)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && latCtrl.text.isNotEmpty && lngCtrl.text.isNotEmpty) {
                await DBHelper().insertShop(Shop(
                  name: nameCtrl.text,
                  lat: double.parse(latCtrl.text),
                  lng: double.parse(lngCtrl.text),
                ));
                Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text("新增"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Shop? selectedShop = shops.isNotEmpty ? shops[selectedIndex] : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("狀態：$statusText", style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
            const Text("清單管理", style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(onPressed: _showAddDialog, icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32)),
        ],
      ),
      body: shops.isEmpty
          ? const Center(child: Text("請點擊右上角新增店家"))
          : Column(
              children: [
                const Divider(),
                // 1. 半徑設定滑桿
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("⚙️ 半徑設定", style: TextStyle(color: Colors.grey)),
                          Text("${selectedShop!.radius.toInt()}m", style: const TextStyle(color: Colors.blue, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text("正在設定：${selectedShop.name}", style: const TextStyle(fontSize: 16)),
                      Slider(
                        value: selectedShop.radius,
                        min: 10, max: 1000,
                        onChanged: (v) => setState(() => selectedShop.radius = v),
                        onChangeEnd: (v) {
                          DBHelper().updateShopRadius(selectedShop.id!, v);
                          GeofenceManager().startGeofencing(shops);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // 2. 店家清單
                Expanded(
                  child: ListView.builder(
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      bool isSelected = index == selectedIndex;
                      final s = shops[index];
                      return GestureDetector(
                        onTap: () => setState(() => selectedIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: 2),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSelected ? Colors.blue : Colors.blue.shade50,
                                child: Text("${index + 1}", style: TextStyle(color: isSelected ? Colors.white : Colors.blue)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("緯度: ${s.lat} / 經度: ${s.lng}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ])),
                              // 刪除按鈕
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.redAccent),
                                onPressed: () async {
                                  await DBHelper().deleteShop(s.id!);
                                  _refreshData();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}