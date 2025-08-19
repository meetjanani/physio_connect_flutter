import 'package:json_annotation/json_annotation.dart';

part 'user_model_supabase.g.dart';

@JsonSerializable()
class UserModelSupabase {
  int id = 0;
  String name = "";
  String userType = "Patient";
  String doctorName = "";
  int doctorId = 0;
  String mobileNumber = "";
  String createAt = DateTime.now().toString();
  String firebaseToken =
      "https://firebasestorage.googleapis.com/v0/b/colab-sample.appspot.com/o/default_placeholder%2Fuser_default_profile_picture.png?alt=media&token=e00268a3-7e48-4586-b06b-99aa449d3f3e";

  UserModelSupabase({
    required this.id,
    required this.name,
    required this.doctorName,
    required this.doctorId,
    required this.mobileNumber,
  });

  static List<UserModelSupabase> fromJsonList(List<dynamic> dataList) {
    List<UserModelSupabase> record = [];
    for (var e in dataList) {
      record.add(_$UserModelSupabaseFromJson(e));
    }
    return record;
  }

  factory UserModelSupabase.fromJson(Map<String, dynamic> data) =>
      _$UserModelSupabaseFromJson(data);

  Map<String, dynamic> toJson() => _$UserModelSupabaseToJson(this);
}