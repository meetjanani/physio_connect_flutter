import 'package:json_annotation/json_annotation.dart';
part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  String name = "";
  String userType = "Patient";
  String mobileNumber = "";
  String doctorName = "PD";
  int doctorId = 1;
  String createAt = DateTime.now().toString();
  String firebaseToken =
      "https://firebasestorage.googleapis.com/v0/b/colab-sample.appspot.com/o/default_placeholder%2Fuser_default_profile_picture.png?alt=media&token=e00268a3-7e48-4586-b06b-99aa449d3f3e";

  UserModel({
    required this.name,
    required this.mobileNumber,
    required this.doctorName,
    required this.doctorId,
  });

  factory UserModel.fromJson(Map<String, dynamic> data) =>
      _$UserModelFromJson(data);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}