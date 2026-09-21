import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
part 'verify_razorpay_payment_order_model.g.dart';

@JsonSerializable()
class VerifyPaymentResponseModel {
  final bool success;
  final bool alreadyPaid;
  final String? message;
  final String? transferId;
  final String? transferStatus;
  final String? error;

  VerifyPaymentResponseModel({
    required this.success,
    this.alreadyPaid = false,
    this.message,
    this.transferId,
    this.transferStatus,
    this.error,
  });

  factory VerifyPaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifyPaymentResponseModel(
      success: json['success'] ?? false,
      alreadyPaid: json['alreadyPaid'] ?? false,
      message: json['message'],
      transferId: json['transferId'],
      transferStatus: json['transferStatus'],
      error: json['error'],
    );
  }
}