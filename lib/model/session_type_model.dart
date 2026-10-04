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
  /// `Home Visit` or `Online`. Missing values are treated as home visit.
  String? mode;

  SessionTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    required this.imageUrl,
    this.mode,
  });

  bool get isOnline {
    final value = (mode ?? '').trim().toLowerCase();
    return value.contains('online');
  }

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
