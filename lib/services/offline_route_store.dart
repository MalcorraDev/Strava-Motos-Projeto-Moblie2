import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineRouteStore {
  static Future<Box<dynamic>> _box() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Entre na sua conta para acessar rotas salvas.');
    }
    return Hive.openBox<dynamic>('offline_routes_$userId');
  }

  static Future<List<Map<String, dynamic>>> list() async {
    final box = await _box();
    return box.values
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  static Future<void> save(Map<String, dynamic> route) async {
    final id = route['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('A viagem não tem um identificador válido.');
    }
    final copy = Map<String, dynamic>.from(route)..['offline_saved'] = true;
    await (await _box()).put(id, copy);
  }

  static Future<void> remove(String id) async {
    await (await _box()).delete(id);
  }
}
