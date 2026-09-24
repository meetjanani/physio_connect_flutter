
import 'package:json_annotation/json_annotation.dart';

part 'refund_response_model.g.dart';

@JsonSerializable()
class RefundResponseModel {
  final bool success;
  final String? message;
  final String? refundId;
  final String? errorMessage;

  RefundResponseModel({
    required this.success,
    this.message,
    this.refundId,
    this.errorMessage,
  });

  static List<RefundResponseModel> fromJsonList(List<dynamic> dataList) {
    return dataList.map((e) => _$RefundResponseModelFromJson(e)).toList();
  }

  factory RefundResponseModel.fromJson(Map<String, dynamic> data) =>
      _$RefundResponseModelFromJson(data);

  Map<String, dynamic> toJson() => _$RefundResponseModelToJson(this);
}