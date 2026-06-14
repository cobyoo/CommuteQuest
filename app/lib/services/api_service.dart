import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/character.dart';
import '../models/commute_result.dart';

class ApiService {
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Auth
  Future<String> signup(String email, String password, String nickname) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/signup'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'nickname': nickname,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    }
    throw Exception(jsonDecode(response.body)['detail']);
  }

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    }
    throw Exception(jsonDecode(response.body)['detail']);
  }

  // Character
  Future<Character> createCharacter(String name) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/characters/'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201) {
      return Character.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['detail']);
  }

  Future<Character> getMyCharacter() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/characters/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Character.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['detail']);
  }

  // Commute
  Future<void> startCommute(String dungeonGrade, DateTime targetArrival) async {
    await http.post(
      Uri.parse('${ApiConstants.baseUrl}/commute/start'),
      headers: _headers,
      body: jsonEncode({
        'dungeon_grade': dungeonGrade,
        'target_arrival': targetArrival.toIso8601String(),
      }),
    );
  }

  Future<CommuteResult> endCommute() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/commute/end'),
      headers: _headers,
      body: jsonEncode({
        'arrived_at': DateTime.now().toIso8601String(),
      }),
    );
    if (response.statusCode == 200) {
      return CommuteResult.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['detail']);
  }

  // Rankings
  Future<List<Map<String, dynamic>>> getRankings(String type) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/rankings/$type'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['rankings']);
    }
    throw Exception('랭킹 조회 실패');
  }
}
