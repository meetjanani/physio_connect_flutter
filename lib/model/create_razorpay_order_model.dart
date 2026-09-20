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

  CreateRazorPayOrderModel({
    required this.success,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.doctorAmount,
    required this.platformFeeAmount,
    required this.message,
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
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  bool get hasOrder => success && (orderId?.isNotEmpty ?? false);

  bool get isExistingOrder =>
      success &&
      (message?.toLowerCase().contains('existing') ?? false);
}
