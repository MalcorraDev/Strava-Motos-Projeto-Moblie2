import 'dart:convert';
import 'package:http/http.dart' as http;

class StravaApi {
  // Configure com --dart-define=STRAVA_API_URL=https://seu-dominio.vercel.app
  static const String baseUrl = String.fromEnvironment(
    'STRAVA_API_URL',
    defaultValue: 'https://strava-motos-api-git-main-soaresmalcorrajoaovitor-1983.vercel.app',
  );
  // UUID de um registro existente em public.usuarios. Não é uma senha.
  static const String usuarioId = String.fromEnvironment('STRAVA_USER_ID');

  static void _checkConfig() {
    if (usuarioId.isEmpty) {
      throw Exception('Falta configurar o usuário do app. Execute com --dart-define=STRAVA_USER_ID=UUID_DO_USUARIO.');
    }
  }

  static Future<dynamic> _request(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    _checkConfig();
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    try {
      final headers = {'Content-Type': 'application/json'};
      if (method == 'GET') {
        response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      } else if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
      } else if (method == 'PATCH') {
        response = await http.patch(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
      } else {
        response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
      }
    } catch (e) {
      throw Exception('Não foi possível acessar a API. Verifique a publicação e sua conexão. ($e)');
    }
    dynamic decoded;
    try { decoded = response.body.isEmpty ? {} : jsonDecode(response.body); }
    catch (_) { throw Exception('A API retornou uma resposta inválida (HTTP ${response.statusCode}).'); }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded is Map ? (decoded['error'] ?? 'Erro HTTP ${response.statusCode}').toString() : 'Erro HTTP ${response.statusCode}.');
    }
    return decoded;
  }

  static Future<List<Map<String, dynamic>>> listarMotos() async {
    final r = await _request('/api/motocicletas?usuario_id=$usuarioId');
    return List<Map<String, dynamic>>.from(r['data'] ?? const []);
  }
  static Future<Map<String, dynamic>> criarMoto({required String modelo, required int cilindrada, double? consumo}) async {
    final r = await _request('/api/motocicletas', method: 'POST', body: {'usuario_id': usuarioId, 'modelo': modelo, 'cilindrada': cilindrada, 'consumo_km_l': consumo});
    return Map<String, dynamic>.from(r['data']);
  }
  static Future<Map<String, dynamic>> editarMoto(String id, Map<String, dynamic> body) async {
    final r = await _request('/api/motocicletas/$id?usuario_id=$usuarioId', method: 'PATCH', body: {...body, 'usuario_id': usuarioId});
    return Map<String, dynamic>.from(r['data']);
  }
  static Future<void> excluirMoto(String id) async { await _request('/api/motocicletas/$id?usuario_id=$usuarioId', method: 'DELETE'); }

  static Future<List<Map<String, dynamic>>> listarViagens() async {
    final r = await _request('/api/viagens?usuario_id=$usuarioId');
    return List<Map<String, dynamic>>.from(r['data'] ?? const []);
  }
  static Future<Map<String, dynamic>> criarViagem(Map<String, dynamic> body) async {
    final r = await _request('/api/viagens', method: 'POST', body: {...body, 'usuario_id': usuarioId});
    return Map<String, dynamic>.from(r['data']);
  }
  static Future<void> excluirViagem(String id) async { await _request('/api/viagens/$id?usuario_id=$usuarioId', method: 'DELETE'); }
  static Future<Map<String, dynamic>> editarViagem(String id, Map<String, dynamic> body) async {
    final r = await _request('/api/viagens/$id?usuario_id=$usuarioId', method: 'PATCH', body: {...body, 'usuario_id': usuarioId});
    return Map<String, dynamic>.from(r['data']);
  }
  static Future<Map<String, dynamic>> perfil() async {
    final r = await _request('/api/usuarios/$usuarioId');
    return Map<String, dynamic>.from(r['data']);
  }
}
