import 'package:json_annotation/json_annotation.dart';
part 'bookings_model.g.dart';

@JsonSerializable()
class BookingsModel {
  int id = 0;
  int userId = 0;
  int timeSlotId = 0;
  int doctorId = 0;
  int sessionId = 0;
  String bookingDate = DateTime.now().toString();
  String createdAt = DateTime.now().toString();

  BookingsModel({
    required this.userId,
    required this.timeSlotId,
    required this.doctorId,
    required this.sessionId,
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