import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const _boxName = 'roommate_box';
  static const _key = 'data_json';

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Map<String, dynamic>? readLocal() {
    final raw = _box.get(_key) as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> writeLocal(Map<String, dynamic> data) async {
    await _box.put(_key, jsonEncode(data));
  }
}
