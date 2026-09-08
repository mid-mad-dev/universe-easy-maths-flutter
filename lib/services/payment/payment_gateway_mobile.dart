import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'payment_gateway_result.dart';

class PaymentGateway {
  final Razorpay _razorpay = Razorpay();
  Completer<PaymentGatewayResult>? _completer;

  PaymentGateway() {
    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handleSuccess,
    );
    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handleError,
    );
    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );
  }

  Future<PaymentGatewayResult> openCheckout({
    required String keyId,
    required int amountPaise,
    required String orderId,
    required String courseName,
    required String email,
  }) {
    if (_completer != null && !_completer!.isCompleted) {
      return _completer!.future;
    }

    _completer = Completer<PaymentGatewayResult>();

    final options = <String, dynamic>{
      'key': keyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'Universe Easy Maths',
      'description': courseName,
      'order_id': orderId,
      'prefill': <String, dynamic>{
        'email': email,
      },
      'theme': <String, dynamic>{
        'color': '#7CF34A',
      },
      'retry': <String, dynamic>{
        'enabled': true,
      },
    };

    try {
      _razorpay.open(options);
    } catch (error) {
      _complete(
        PaymentGatewayResult(
          success: false,
          error: error.toString(),
        ),
      );
    }

    return _completer!.future;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _complete(
      PaymentGatewayResult(
        success: true,
        paymentId: response.paymentId,
        orderId: response.orderId,
        signature: response.signature,
      ),
    );
  }

  void _handleError(PaymentFailureResponse response) {
    _complete(
      PaymentGatewayResult(
        success: false,
        error: response.message ?? 'Payment failed.',
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _complete(
      PaymentGatewayResult(
        success: false,
        error: 'External wallet selected: ${response.walletName}',
      ),
    );
  }

  void _complete(PaymentGatewayResult result) {
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  void dispose() {
    _razorpay.clear();
    _completer = null;
  }
}
