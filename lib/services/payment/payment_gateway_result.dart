class PaymentGatewayResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? error;

  const PaymentGatewayResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.error,
  });
}
