import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FapshiService {
  static const _apiUrl = String.fromEnvironment('FIXMATE_API_URL');

  Future<PaymentCheckout> createSubscriptionCheckout(String plan) async {
    final payload = await _post('/api/subscriptions/checkout', {'plan': plan});
    final link = payload['link'];
    final transId = payload['transId'];
    if (link is! String || transId is! String) {
      throw const FapshiException(
        'The checkout service returned an invalid response.',
      );
    }
    final uri = Uri.tryParse(link);
    if (uri == null ||
        uri.scheme != 'https' ||
        (uri.host != 'fapshi.com' && !uri.host.endsWith('.fapshi.com'))) {
      throw const FapshiException(
        'The checkout service returned an invalid payment link.',
      );
    }
    return PaymentCheckout(link: uri, transId: transId);
  }

  Future<String> checkSubscriptionStatus(String transId) async {
    final payload = await _post(
      '/api/subscriptions/${Uri.encodeComponent(transId)}/status',
      const {},
    );
    final status = payload['status'];
    if (status is! String) {
      throw const FapshiException(
        'The payment service returned an invalid status.',
      );
    }
    return status;
  }

  Future<ProductOrderCheckout> createProductOrderCheckout(
    List<Map<String, Object>> items,
    String checkoutId,
  ) async {
    final payload = await _post('/api/orders/checkout', {
      'items': items,
      'checkoutId': checkoutId,
    });
    final link = payload['link'];
    final transId = payload['transId'];
    final orderId = payload['orderId'];
    if (link is! String || transId is! String || orderId is! String) {
      throw const FapshiException(
        'The checkout service returned an invalid response.',
      );
    }
    final uri = Uri.tryParse(link);
    if (uri == null ||
        uri.scheme != 'https' ||
        (uri.host != 'fapshi.com' && !uri.host.endsWith('.fapshi.com'))) {
      throw const FapshiException(
        'The checkout service returned an invalid payment link.',
      );
    }
    return ProductOrderCheckout(link: uri, orderId: orderId, transId: transId);
  }

  Future<String> checkProductOrderStatus(String orderId) async {
    final payload = await _post(
      '/api/orders/${Uri.encodeComponent(orderId)}/status',
      const {},
    );
    final status = payload['status'];
    if (status is! String) {
      throw const FapshiException(
        'The payment service returned an invalid status.',
      );
    }
    return status;
  }

  Future<ProductOrderRecovery> recoverProductOrderCheckout(
    String checkoutId,
  ) async {
    final payload = await _post('/api/orders/recover', {
      'checkoutId': checkoutId,
    });
    final orderId = payload['orderId'];
    final status = payload['status'];
    final link = payload['link'];
    final transId = payload['transId'];
    if (orderId is! String || status is! String) {
      throw const FapshiException(
        'The checkout service returned an invalid recovery response.',
      );
    }
    final uri = link is String ? Uri.tryParse(link) : null;
    if (uri != null &&
        (uri.scheme != 'https' ||
            (uri.host != 'fapshi.com' && !uri.host.endsWith('.fapshi.com')))) {
      throw const FapshiException(
        'The checkout service returned an invalid payment link.',
      );
    }
    return ProductOrderRecovery(
      orderId: orderId,
      status: status,
      link: uri,
      transId: transId is String ? transId : null,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final baseUrl = _apiUrl.replaceFirst(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) {
      throw const FapshiException('The payment service is not configured.');
    }
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw const FapshiException(
        'Please sign in again before making a payment.',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));
      final payload = jsonDecode(response.body);
      if (payload is Map<String, dynamic> &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        return payload;
      }
      if (payload is Map<String, dynamic> && payload['error'] is String) {
        throw FapshiException(
          payload['error'] as String,
          retryable: payload['retryable'] == true,
          statusCode: response.statusCode,
        );
      }
      throw const FapshiException('Payment request failed. Please try again.');
    } on FapshiException {
      rethrow;
    } catch (_) {
      throw const FapshiException(
        'The payment service is unavailable. Please check your connection and try again.',
      );
    }
  }
}

class PaymentCheckout {
  final Uri link;
  final String transId;

  const PaymentCheckout({required this.link, required this.transId});
}

class ProductOrderCheckout {
  final Uri link;
  final String orderId;
  final String transId;

  const ProductOrderCheckout({
    required this.link,
    required this.orderId,
    required this.transId,
  });
}

class ProductOrderRecovery {
  final String orderId;
  final String status;
  final Uri? link;
  final String? transId;

  const ProductOrderRecovery({
    required this.orderId,
    required this.status,
    required this.link,
    required this.transId,
  });
}

class FapshiException implements Exception {
  final String message;
  final bool retryable;
  final int? statusCode;

  const FapshiException(
    this.message, {
    this.retryable = false,
    this.statusCode,
  });

  @override
  String toString() => message;
}
