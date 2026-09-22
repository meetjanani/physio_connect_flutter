import 'package:json_annotation/json_annotation.dart';
part 'area_model.g.dart';

@JsonSerializable()
class AreaModel {
  int id = 0;
  String areaName = "";
  String description = "";
  int? cityStateId;
  int? doctorId;
  int? orderBy;
  bool isActive = true;

  AreaModel({
    required this.id,
    required this.areaName,
    required this.description,
    this.cityStateId,
    this.doctorId,
    this.orderBy,
    required this.isActive,
  });

  static List<AreaModel> fromJsonList(List<dynamic> dataList) {
    return dataList.map((e) => _$AreaModelFromJson(e)).toList();
  }

  factory AreaModel.fromJson(Map<String, dynamic> data) =>
      _$AreaModelFromJson(data);

  Map<String, dynamic> toJson() => _$AreaModelToJson(this);
}
