// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_razorpay_payment_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyPaymentResponseModel _$VerifyPaymentResponseModelFromJson(
  Map<String, dynamic> json,
) => VerifyPaymentResponseModel(
  success: json['success'] as bool,
  alreadyPaid: json['alreadyPaid'] as bool? ?? false,
  message: json['message'] as String?,
  transferId: json['transferId'] as String?,
  transferStatus: json['transferStatus'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$VerifyPaymentResponseModelToJson(
  VerifyPaymentResponseModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'alreadyPaid': instance.alreadyPaid,
  'message': instance.message,
  'transferId': instance.transferId,
  'transferStatus': instance.transferStatus,
  'error': instance.error,
};
