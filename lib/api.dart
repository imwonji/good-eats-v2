import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL of the local json-server.
/// - Chrome / Windows / macOS / iOS simulator: http://localhost:3000 (default)
/// - Android emulator: run with --dart-define=API_BASE=http://10.0.2.2:3000
const String apiBase =
    String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:3000');

/// GET only — this project never sends POST / PUT / DELETE.
class Api {
  static Future<List<dynamic>> getList(String path) async {
    // Short delay so the loading state is visible during the demo. // P01
    await Future.delayed(const Duration(milliseconds: 700));
    final res = await http
        .get(Uri.parse('$apiBase/$path'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) {
      throw Exception('Server responded ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  static Future<List<dynamic>> groups() => getList('groups');
  static Future<List<dynamic>> pairs() => getList('pairs');
  static Future<List<dynamic>> archived() => getList('archived');
  static Future<List<dynamic>> recommendation(int groupId) =>
      getList('recommendations?groupId=$groupId');
}
