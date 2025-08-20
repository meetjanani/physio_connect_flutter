import 'package:json_annotation/json_annotation.dart';
part 'bookings_model.g.dart';

@JsonSerializable()
class BookingsModel {
  int id = 0;
  int userId = 0;
  int timeSlotId = 0;
  String timeSlotJson = "";
  int doctorId = 0;
  String doctorJson = "";
  int sessionTypeId = 0;
  String sessionTypeJson = "";
  String bookingDate = DateTime.now().toString();
  String createdAt = DateTime.now().toString();

  BookingsModel({
    required this.id,
    required this.userId,
    required this.timeSlotId,
    required this.timeSlotJson,
    required this.doctorId,
    required this.doctorJson,
    required this.sessionTypeId,
    required this.sessionTypeJson,
    required this.bookingDate,
    required this.createdAt,
  });

  static List<BookingsModel> fromJsonList(List<dynamic> dataList) {
    List<BookingsModel> record = [];
    for (var e in dataList) {
      record.add(_$BookingsModelFromJson(e));
    }
    return record;
  }

  factory BookingsModel.fromJson(Map<String, dynamic> data) =>
      _$BookingsModelFromJson(data);

  Map<String, dynamic> toJson() => _$BookingsModelToJson(this);
}