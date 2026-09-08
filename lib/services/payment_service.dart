import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';
import 'payment/payment_gateway.dart';

class PaymentService {
  final SupabaseClient supabase = Supabase.instance.client;
  PaymentGateway? _gateway;

  /// Returns true when a payment was completed, false when the course is
  /// already owned or does not require payment.
  Future<bool> startCoursePayment({
    required String courseId,
    required String courseName,
    required double amount,
    required String email,
  }) async {
    if (kIsWeb) {
      throw Exception(
        'Razorpay checkout is available on Android and iOS. '
        'Build the mobile app to make a payment.',
      );
    }

    if (amount <= 0) {
      throw Exception('This course is free.');
    }

    final response = await supabase.functions.invoke(
      'create-payment-order',
      body: <String, dynamic>{'course_id': courseId},
    );

    if (response.status >= 400) {
      throw Exception(_readError(response.data));
    }

    final raw = response.data;
    if (raw is! Map) {
      throw Exception('Invalid payment-order response.');
    }

    final order = Map<String, dynamic>.from(raw);

    if (order['already_owned'] == true) {
      return false;
    }

    if (order['free'] == true) {
      return false;
    }

    final orderId = order['order_id']?.toString();
    final serverKeyId = order['key_id']?.toString().trim();
    final keyId = (serverKeyId == null || serverKeyId.isEmpty)
        ? AppConstants.razorpayKeyId.trim()
        : serverKeyId;
    final orderAmount = (order['amount'] as num?)?.toInt();

    if (orderId == null || orderId.isEmpty) {
      throw Exception('The payment order did not contain an order ID.');
    }

    if (orderAmount == null || orderAmount <= 0) {
      throw Exception('The payment order amount is invalid.');
    }

    if (keyId.isEmpty || keyId.startsWith('YOUR_')) {
      throw Exception('Razorpay Key ID is not configured.');
    }

    _gateway ??= PaymentGateway();

    final result = await _gateway!.openCheckout(
      keyId: keyId,
      amountPaise: orderAmount,
      orderId: orderId,
      courseName: courseName,
      email: email,
    );

    if (!result.success) {
      throw Exception(result.error ?? 'Payment was not completed.');
    }

    final paymentId = result.paymentId;
    final signature = result.signature;

    if (paymentId == null || paymentId.isEmpty) {
      throw Exception('Payment ID was not returned by Razorpay.');
    }

    if (signature == null || signature.isEmpty) {
      throw Exception('Payment signature was not returned by Razorpay.');
    }

    final verification = await supabase.functions.invoke(
      'verify-razorpay-payment',
      body: <String, dynamic>{
        'course_id': courseId,
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );

    if (verification.status >= 400) {
      throw Exception(_readError(verification.data));
    }

    final resultData = verification.data;
    if (resultData is! Map || resultData['success'] != true) {
      throw Exception(_readError(verification.data));
    }

    return true;
  }

  void dispose() {
    _gateway?.dispose();
    _gateway = null;
  }

  String _readError(dynamic data) {
    if (data is Map) {
      final error = data['error'] ?? data['message'];
      if (error != null) {
        return error.toString();
      }
    }
    return data?.toString() ?? 'Payment request failed.';
  }
}
