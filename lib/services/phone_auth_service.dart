import 'dart:convert';
import 'package:http/http.dart' as http;

class PhoneAuthService {
  const PhoneAuthService();

  static const _apiUrl = String.fromEnvironment('FIXMATE_API_URL');

  Future<String> signIn({
    required String phone,
    required String password,
  }) async {
    final baseUrl = _apiUrl.replaceFirst(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) {
      throw const PhoneAuthException('Phone sign-in is not configured.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/phone-login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));
      final payload = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          payload is Map<String, dynamic> &&
          payload['refreshToken'] is String) {
        return payload['refreshToken'] as String;
      }
      if (payload is Map<String, dynamic> && payload['error'] is String) {
        throw PhoneAuthException(payload['error'] as String);
      }
      throw const PhoneAuthException('Phone sign-in failed. Please try again.');
    } on PhoneAuthException {
      rethrow;
    } catch (_) {
      throw const PhoneAuthException(
        'Phone sign-in is unavailable. Please check your connection and try again.',
      );
    }
  }
}

class PhoneAuthException implements Exception {
  final String message;

  const PhoneAuthException(this.message);

  @override
  String toString() => message;
}
