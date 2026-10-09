import 'dart:convert';
import 'package:http/http.dart' as http;

class PhoneAuthService {
  const PhoneAuthService();

  static const _apiUrl = String.fromEnvironment('FIXMATE_API_URL');

  Future<void> sendWhatsappSignupCode({required String phone}) async {
    final baseUrl = _baseUrl;
    await _post(Uri.parse('$baseUrl/api/auth/signup/whatsapp/send'), {
      'phone': phone,
    });
  }

  Future<PhoneSignupSession> verifyWhatsappSignupCode({
    required String phone,
    required String email,
    required String password,
    required String code,
    required String role,
    required String fullName,
    required String region,
    required String town,
    List<String>? services,
    List<String>? categories,
    String? additionalPhone,
  }) async {
    final payload = await _post(Uri.parse('$_baseUrl/api/auth/signup/whatsapp/verify'), {
      'phone': phone,
      'email': email,
      'password': password,
      'code': code,
      'role': role,
      'fullName': fullName,
      'region': region,
      'town': town,
      'services': services,
      'categories': categories,
      'additionalPhone': additionalPhone,
    });
    if (payload['refreshToken'] is! String) {
      throw const PhoneAuthException(
        'Could not complete signup. Please try again.',
      );
    }
    return PhoneSignupSession(refreshToken: payload['refreshToken'] as String);
  }

  Future<String> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      final payload = await _post(Uri.parse('$_baseUrl/api/auth/phone-login'), {
        'phone': phone,
        'password': password,
      });
      if (payload['refreshToken'] is String) {
        return payload['refreshToken'] as String;
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

  String get _baseUrl {
    final value = _apiUrl.replaceFirst(RegExp(r'/+$'), '');
    if (value.isEmpty) {
      throw const PhoneAuthException('Phone verification is not configured.');
    }
    return value;
  }

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      final payload = jsonDecode(response.body);
      if (payload is Map<String, dynamic> && response.statusCode < 300) {
        return payload;
      }
      if (payload is Map<String, dynamic> && payload['error'] is String) {
        throw PhoneAuthException(payload['error'] as String);
      }
      throw const PhoneAuthException('Request failed. Please try again.');
    } on PhoneAuthException {
      rethrow;
    } catch (_) {
      throw const PhoneAuthException(
        'Phone verification is unavailable. Please check your connection and try again.',
      );
    }
  }
}

class PhoneSignupSession {
  final String refreshToken;

  const PhoneSignupSession({required this.refreshToken});
}

class PhoneAuthException implements Exception {
  final String message;

  const PhoneAuthException(this.message);

  @override
  String toString() => message;
}
