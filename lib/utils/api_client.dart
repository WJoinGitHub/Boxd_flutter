import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = 'http://localhost:8080/app';
  static const String clientId = 'your_client_id';
  static const String clientSecret = 'your_client_secret';

  /// 生成随机 nonce（32位）
  static String _generateNonce([int length = 32]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }

  /// 生成签名
  static String _generateSignature(
      String timestamp, String nonce, String body) {
    final signString = clientId + timestamp + nonce + body + clientSecret;
    final bytes = utf8.encode(signString);
    return sha256.convert(bytes).toString();
  }

  /// 发送 POST 请求
  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$path');
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = _generateNonce();
    final bodyStr = jsonEncode(body);
    final signature = _generateSignature(timestamp, nonce, bodyStr);

    final headers = {
      'Content-Type': 'application/json',
      'X-Client-ID': clientId,
      'X-Timestamp': timestamp,
      'X-Nonce': nonce,
      'X-Signature': signature,
    };

    final response = await http.post(url, headers: headers, body: bodyStr);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
