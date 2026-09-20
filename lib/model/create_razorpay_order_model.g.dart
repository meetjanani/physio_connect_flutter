// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_razorpay_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateRazorPayOrderModel _$CreateRazorPayOrderModelFromJson(
  Map<String, dynamic> json,
) => CreateRazorPayOrderModel(
  success: json['success'] as bool,
  orderId: json['orderId'] as String,
  amount: (json['amount'] as num).toInt(),
  currency: json['currency'] as String,
  keyId: json['keyId'] as String,
  doctorAmount: (json['doctorAmount'] as num).toInt(),
  platformFeeAmount: (json['platformFeeAmount'] as num).toInt(),
  message: json['message'] as String,
);

Map<String, dynamic> _$CreateRazorPayOrderModelToJson(
  CreateRazorPayOrderModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'orderId': instance.orderId,
  'amount': instance.amount,
  'currency': instance.currency,
  'keyId': instance.keyId,
  'doctorAmount': instance.doctorAmount,
  'platformFeeAmount': instance.platformFeeAmount,
  'message': instance.message,
};
