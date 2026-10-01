import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  // Platform-aware base URL:
  //   Web / Windows desktop  -> localhost
  //   Android emulator       -> 10.0.2.2
  //   Physical phone         -> replace with your PC LAN IP later
  static String get base {
    if (kIsWeb) return 'http://localhost:4000';
    if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    return 'http://localhost:4000';
  }

  static String? token;

  static Future<void> loadToken() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
  }

  static Future<void> saveToken(String? t) async {
    token = t;
    final p = await SharedPreferences.getInstance();
    if (t == null) {
      await p.remove('token');
    } else {
      await p.setString('token', t);
    }
  }

  static Map<String, String> headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Uri u(String path) => Uri.parse('$base/api$path');
  static String url(String path) =>
      path.startsWith('http') ? path : '$base$path';

  static dynamic _dec(http.Response r) {
    final body = r.body.isEmpty ? {} : jsonDecode(r.body);
    if (r.statusCode >= 400) {
      final msg = (body is Map && body['error'] != null)
          ? body['error']
          : 'Request failed (${r.statusCode})';
      throw Exception(msg);
    }
    return body;
  }

  static Future<dynamic> get(String p) async =>
      _dec(await http.get(u(p), headers: headers()));

  static Future<dynamic> post(String p, Map body) async =>
      _dec(await http.post(u(p), headers: headers(), body: jsonEncode(body)));

  static Future<dynamic> put(String p, Map body) async =>
      _dec(await http.put(u(p), headers: headers(), body: jsonEncode(body)));

  static Future<dynamic> patch(String p, Map body) async =>
      _dec(await http.patch(u(p), headers: headers(), body: jsonEncode(body)));

  static Future<dynamic> delete(String p) async =>
      _dec(await http.delete(u(p), headers: headers()));

  // For desktop / mobile: upload a File directly.
  static Future<String> uploadImage(File file) async {
    final req = http.MultipartRequest('POST', u('/upload'))
      ..headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await http.Response.fromStream(await req.send());
    return _dec(res)['url'];
  }

  // For web (Chrome) and anywhere you already have bytes:
  // Flutter web has no dart:io File, so we send the raw bytes instead.
  static Future<String> uploadImageBytes(
    List<int> bytes,
    String filename,
  ) async {
    final req = http.MultipartRequest('POST', u('/upload'))
      ..headers.addAll({
        if (token != null) 'Authorization': 'Bearer $token',
      })
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    final res = await http.Response.fromStream(await req.send());
    return _dec(res)['url'];
  }
}