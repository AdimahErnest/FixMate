
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://fixmate-api-7bnd.onrender.com';

  static Future<Map<String, dynamic>> checkHealth() async {
    final response = await http
        .get(Uri.parse('$baseUrl/health/live'))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'API request failed: ${response.statusCode}',
    );
  }
}
