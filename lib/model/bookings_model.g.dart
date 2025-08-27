// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingsModel _$BookingsModelFromJson(Map<String, dynamic> json) =>
    BookingsModel(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      bookingStatus: json['bookingStatus'] as String,
      price: (json['price'] as num).toInt(),
      timeSlotId: (json['timeSlotId'] as num).toInt(),
      timeSlotJson: json['timeSlotJson'] as String,
      doctorId: (json['doctorId'] as num).toInt(),
      doctorJson: json['doctorJson'] as String,
      sessionTypeId: (json['sessionTypeId'] as num).toInt(),
      sessionTypeJson: json['sessionTypeJson'] as String,
      paymentStatus: json['paymentStatus'] as String,
      paymentId: json['paymentId'] as String?,
      orderId: json['orderId'] as String?,
      signature: json['signature'] as String?,
      doctorNotes: json['doctorNotes'] as String?,
      bookingDate: json['bookingDate'] as String,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$BookingsModelToJson(BookingsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'bookingStatus': instance.bookingStatus,
      'price': instance.price,
      'timeSlotId': instance.timeSlotId,
      'timeSlotJson': instance.timeSlotJson,
      'doctorId': instance.doctorId,
      'doctorJson': instance.doctorJson,
      'sessionTypeId': instance.sessionTypeId,
      'sessionTypeJson': instance.sessionTypeJson,
      'paymentStatus': instance.paymentStatus,
      'paymentId': instance.paymentId,
      'orderId': instance.orderId,
      'signature': instance.signature,
      'doctorNotes': instance.doctorNotes,
      'bookingDate': instance.bookingDate,
      'createdAt': instance.createdAt,
    };
