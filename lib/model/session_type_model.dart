import 'package:json_annotation/json_annotation.dart';
part 'session_type_model.g.dart';

@JsonSerializable()
class SessionTypeModel {
  int id = 0;
  String name = "";
  String description= "";
  String duration= "";
  int price = 0;
  String? imageUrl= null;

  SessionTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    required this.imageUrl,
  });

  static List<SessionTypeModel> fromJsonList(List<dynamic> dataList) {
    List<SessionTypeModel> record = [];
    for (var e in dataList) {
      record.add(_$SessionTypeModelFromJson(e));
    }
    return record;
  }

  factory SessionTypeModel.fromJson(Map<String, dynamic> data) =>
      _$SessionTypeModelFromJson(data);

  Map<String, dynamic> toJson() => _$SessionTypeModelToJson(this);
}