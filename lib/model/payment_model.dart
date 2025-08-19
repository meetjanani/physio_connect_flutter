// lib/models/payment_model.dart
class PaymentModel {
  final String paymentId;
  final String appointmentId;
  final double amount;
  final String? razorpayPaymentId;
  final String status;
  final DateTime timestamp;

  PaymentModel({
    required this.paymentId,
    required this.appointmentId,
    required this.amount,
    this.razorpayPaymentId,
    required this.status,
    required this.timestamp,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId'],
      appointmentId: json['appointmentId'],
      amount: json['amount'],
      razorpayPaymentId: json['razorpayPaymentId'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'appointmentId': appointmentId,
      'amount': amount,
      'razorpayPaymentId': razorpayPaymentId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}