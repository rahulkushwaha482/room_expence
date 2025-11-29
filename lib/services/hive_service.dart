import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const _box = 'roommate_box';
  static const _key = 'data_json';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_box);
  }

  static Map<String, dynamic>? readLocal() {
    final box = Hive.box(_box);
    final raw = box.get(_key) as String?;
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> writeLocal(Map<String, dynamic> data) async {
    final box = Hive.box(_box);
    await box.put(_key, jsonEncode(data));
  }
}
