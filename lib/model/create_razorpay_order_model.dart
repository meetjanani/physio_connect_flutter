import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
part 'create_razorpay_order_model.g.dart';

@JsonSerializable()
class CreateRazorPayOrderModel {
  bool success;
  String orderId;
  int amount;
  String currency;
  String keyId;
  int doctorAmount;
  int platformFeeAmount;
  String message;

  /// Web only: Razorpay Payment Link (UPI intent / hosted page) and UPI QR
  /// image created by `create-razorpay-order` when `channel == 'web'`.
  /// The website can't embed Razorpay Checkout until the domain is approved.
  String? paymentLinkUrl;
  String? qrCodeUrl;

  /// Web only: Razorpay's reason when neither a link nor a QR could be made.
  String? webPaymentError;

  CreateRazorPayOrderModel({
    required this.success,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.doctorAmount,
    required this.platformFeeAmount,
    required this.message,
    this.paymentLinkUrl,
    this.qrCodeUrl,
    this.webPaymentError,
  });

  factory CreateRazorPayOrderModel.fromJson(Map<String, dynamic> json) {
    return CreateRazorPayOrderModel(
      success: json['success'] as bool ?? false,
      orderId: json['orderId']?.toString() ?? "",
      amount: _parseInt(json['amount']) ?? 0,
      currency: json['currency']?.toString() ?? "",
      keyId: json['keyId']?.toString() ?? "",
      doctorAmount: _parseInt(json['doctorAmount']) ?? 0,
      platformFeeAmount: _parseInt(json['platformFeeAmount']) ?? 0,
      message: json['message']?.toString() ?? "",
      paymentLinkUrl: _nonEmpty(json['paymentLinkUrl'] ?? json['payment_link_url']),
      qrCodeUrl: _nonEmpty(json['qrCodeUrl'] ?? json['qr_code_url']),
      webPaymentError: _nonEmpty(json['webPaymentError']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'keyId': keyId,
      'doctorAmount': doctorAmount,
      'platformFeeAmount': platformFeeAmount,
      'message': message,
      'paymentLinkUrl': paymentLinkUrl,
      'qrCodeUrl': qrCodeUrl,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty || text == 'null') ? null : text;
  }

  bool get hasWebPaymentOption => paymentLinkUrl != null || qrCodeUrl != null;

  bool get hasOrder => success && (orderId?.isNotEmpty ?? false);

  bool get isExistingOrder =>
      success &&
      (message?.toLowerCase().contains('existing') ?? false);
}
