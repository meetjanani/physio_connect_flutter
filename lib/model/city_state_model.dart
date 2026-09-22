import 'package:json_annotation/json_annotation.dart';
part 'city_state_model.g.dart';

@JsonSerializable()
class CityStateModel {
  int id = 0;
  String cityStateName = "";
  String description = "";
  bool isActive = true;
  // int orderBy = 0;

  CityStateModel({
    required this.id,
    required this.cityStateName,
    required this.description,
    required this.isActive,
    // required this.orderBy,
  });

  static List<CityStateModel> fromJsonList(List<dynamic> dataList) {
    return dataList.map((e) => _$CityStateModelFromJson(e)).toList();
  }

  factory CityStateModel.fromJson(Map<String, dynamic> data) =>
      _$CityStateModelFromJson(data);

  Map<String, dynamic> toJson() => _$CityStateModelToJson(this);
}
