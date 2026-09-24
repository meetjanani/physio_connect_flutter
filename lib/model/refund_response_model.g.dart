// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefundResponseModel _$RefundResponseModelFromJson(Map<String, dynamic> json) =>
    RefundResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String?,
      refundId: json['refundId'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$RefundResponseModelToJson(
  RefundResponseModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'refundId': instance.refundId,
  'errorMessage': instance.errorMessage,
};
