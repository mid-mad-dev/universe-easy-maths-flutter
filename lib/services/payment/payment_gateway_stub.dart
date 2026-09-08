import 'payment_gateway_result.dart';

class PaymentGateway {
  Future<PaymentGatewayResult> openCheckout({
    required String keyId,
    required int amountPaise,
    required String orderId,
    required String courseName,
    required String email,
  }) async {
    return const PaymentGatewayResult(
      success: false,
      error:
          'Razorpay checkout is available on Android and iOS. '
          'Use a mobile build to test payments.',
    );
  }

  void dispose() {}
}
