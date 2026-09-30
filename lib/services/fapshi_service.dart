import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FapshiService {
  // ⚠️ IMPORTANT: Get these from your Fapshi Dashboard (Developers > API Keys)
  // For testing, use your Sandbox keys. For production, use Live keys.
  final String apiUser = '4d542a90-ee75-4752-8e6e-857073558fab'; 
  final String apiKey = 'FAK_TEST_b910de728474b584a976'; 
  
  // Choose your environment:
  final String baseUrl = 'https://sandbox.fapshi.com'; // Change to 'https://live.fapshi.com' for production

  /// Initiates a payment and returns the Fapshi payment link
  Future<String?> initiatePayment({
    
    required int amount, // Must be >= 100 (in XAF)
    required String externalId, // Your unique order ID
    String? email,
    String? redirectUrl,
    String? message,
  }) async {
    final url = Uri.parse('$baseUrl/initiate-pay');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apiuser': apiUser,   // Required by Fapshi
          'apikey': apiKey,     // Required by Fapshi
        },
       body: jsonEncode({
  'amount': amount,
  'externalId': externalId,
  ...?(email != null ? {'email': email} : null),
  ...?(redirectUrl != null ? {'redirectUrl': redirectUrl} : null),
  ...?(message != null ? {'message': message} : null),
}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Fapshi returns the payment URL in the 'link' field
        return data['link']; 
      } else {
  debugPrint('Fapshi API Error (${response.statusCode}): ${data['message']}');
  return null;
}
} catch (e) {
  debugPrint('Network Error: $e');
  return null;

  
}



  }

    /// Sends a direct payment prompt to the user's phone (Orange/MTN)
  Future<Map<String, dynamic>?> directPayment({
    required int amount,
    required String phone,
    required String medium, // 'mobile money' (MTN) or 'orange money'
    required String externalId,
    String? message,
  }) async {
    final url = Uri.parse('$baseUrl/direct-pay');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apiuser': apiUser,
          'apikey': apiKey,
        },
        body: jsonEncode({
          'amount': amount,
          'phone': phone,
          'medium': medium,
          'externalId': externalId,
        ...?(message != null ? {'message': message} : null),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // Returns {message, transId, dateInitiated}
      } else {
        debugPrint('Fapshi Direct Pay Error: ${data['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Network Error: $e');
      return null;
    }
  }
}
