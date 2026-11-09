import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class StravaApi {
  static const String baseUrl = String.fromEnvironment(
    'STRAVA_API_URL',
    defaultValue: 'https://strava-motos-api.vercel.app',
  );

  static Future<dynamic> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Sua sessão expirou. Entre novamente com o Google.');
    }

    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };

    late http.Response response;
    try {
      if (method == 'GET') {
        response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
      } else if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
      } else if (method == 'PATCH') {
        response = await http.patch(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
      } else {
        response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
      }
    } catch (error) {
      throw Exception('Não foi possível acessar a API. Verifique a publicação e sua conexão. ($error)');
    }

    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    } catch (_) {
      throw Exception('A API retornou uma resposta inválida (HTTP ${response.statusCode}).');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['error'] ?? 'Erro HTTP ${response.statusCode}').toString()
          : 'Erro HTTP ${response.statusCode}.';
      throw Exception(
        '$message (HTTP ${response.statusCode}; $method $path)',
      );
    }
    return decoded;
  }

  static Future<List<Map<String, dynamic>>> listarMotos() async {
    final response = await _request('/api/motocicletas');
    return List<Map<String, dynamic>>.from(response['data'] ?? const []);
  }

  static Future<Map<String, dynamic>> criarMoto({
    required String modelo,
    required int cilindrada,
    double? consumo,
  }) async {
    final response = await _request(
      '/api/motocicletas',
      method: 'POST',
      body: {'modelo': modelo, 'cilindrada': cilindrada, 'consumo_km_l': consumo},
    );
    return Map<String, dynamic>.from(response['data']);
  }

  static Future<Map<String, dynamic>> editarMoto(String id, Map<String, dynamic> body) async {
    final response = await _request('/api/motocicletas/${Uri.encodeComponent(id)}', method: 'PATCH', body: body);
    return Map<String, dynamic>.from(response['data']);
  }

  static Future<void> excluirMoto(String id) async {
    await _request('/api/motocicletas/${Uri.encodeComponent(id)}', method: 'DELETE');
  }

  static Future<List<Map<String, dynamic>>> listarViagens() async {
    final response = await _request('/api/viagens');
    return List<Map<String, dynamic>>.from(response['data'] ?? const []);
  }

  static Future<Map<String, dynamic>> criarViagem(Map<String, dynamic> body) async {
    final response = await _request('/api/viagens', method: 'POST', body: body);
    return Map<String, dynamic>.from(response['data']);
  }

  static Future<void> excluirViagem(String id) async {
    await _request('/api/viagens/${Uri.encodeComponent(id)}', method: 'DELETE');
  }

  static Future<Map<String, dynamic>> editarViagem(String id, Map<String, dynamic> body) async {
    final response = await _request('/api/viagens/${Uri.encodeComponent(id)}', method: 'PATCH', body: body);
    return Map<String, dynamic>.from(response['data']);
  }

  static Future<Map<String, dynamic>> perfil() async {
    final response = await _request('/api/usuarios/me');
    return Map<String, dynamic>.from(response['data']);
  }
}
