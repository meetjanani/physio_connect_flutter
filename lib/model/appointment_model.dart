// lib/models/appointment_model.dart
class AppointmentModel {
  final String appointmentId;
  final String userId;
  final String therapistId;
  final String sessionTypeId;
  final String sessionTypeName;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String paymentStatus;
  final double amount;
  final String therapistName;
  final String therapistImage;
  final DateTime createdAt;

  AppointmentModel({
    required this.appointmentId,
    required this.userId,
    required this.therapistId,
    required this.sessionTypeId,
    required this.sessionTypeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.paymentStatus,
    required this.amount,
    required this.therapistName,
    required this.therapistImage,
    required this.createdAt,
  });

  AppointmentModel copyWith({
    String? appointmentId,
    String? userId,
    String? therapistId,
    String? sessionTypeId,
    String? sessionTypeName,
    String? date,
    String? startTime,
    String? endTime,
    String? status,
    String? paymentStatus,
    double? amount,
    String? therapistName,
    String? therapistImage,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId ?? this.appointmentId,
      userId: userId ?? this.userId,
      therapistId: therapistId ?? this.therapistId,
      sessionTypeId: sessionTypeId ?? this.sessionTypeId,
      sessionTypeName: sessionTypeName ?? this.sessionTypeName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amount: amount ?? this.amount,
      therapistName: therapistName ?? this.therapistName,
      therapistImage: therapistImage ?? this.therapistImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AppointmentDetails extends AppointmentModel {
  final int durationMinutes;
  final String razorpayPaymentId;
  final String therapistSpecialization;
  final int therapistExperience;
  final double therapistRating;
  final String doctorNotes;

  AppointmentDetails({
    required String appointmentId,
    required String userId,
    required String therapistId,
    required String sessionTypeId,
    required String sessionTypeName,
    required String date,
    required String startTime,
    required String endTime,
    required String status,
    required String paymentStatus,
    required double amount,
    required String therapistName,
    required String therapistImage,
    required DateTime createdAt,
    required this.durationMinutes,
    required this.razorpayPaymentId,
    required this.therapistSpecialization,
    required this.therapistExperience,
    required this.therapistRating,
    required this.doctorNotes,
  }) : super(
          appointmentId: appointmentId,
          userId: userId,
          therapistId: therapistId,
          sessionTypeId: sessionTypeId,
          sessionTypeName: sessionTypeName,
          date: date,
          startTime: startTime,
          endTime: endTime,
          status: status,
          paymentStatus: paymentStatus,
          amount: amount,
          therapistName: therapistName,
          therapistImage: therapistImage,
          createdAt: createdAt,
        );

  AppointmentDetails copyWith({
    String? appointmentId,
    String? userId,
    String? therapistId,
    String? sessionTypeId,
    String? sessionTypeName,
    String? date,
    String? startTime,
    String? endTime,
    String? status,
    String? paymentStatus,
    double? amount,
    String? therapistName,
    String? therapistImage,
    DateTime? createdAt,
    int? durationMinutes,
    String? razorpayPaymentId,
    String? therapistSpecialization,
    int? therapistExperience,
    double? therapistRating,
    String? doctorNotes,
  }) {
    return AppointmentDetails(
      appointmentId: appointmentId ?? this.appointmentId,
      userId: userId ?? this.userId,
      therapistId: therapistId ?? this.therapistId,
      sessionTypeId: sessionTypeId ?? this.sessionTypeId,
      sessionTypeName: sessionTypeName ?? this.sessionTypeName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amount: amount ?? this.amount,
      therapistName: therapistName ?? this.therapistName,
      therapistImage: therapistImage ?? this.therapistImage,
      createdAt: createdAt ?? this.createdAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      therapistSpecialization: therapistSpecialization ?? this.therapistSpecialization,
      therapistExperience: therapistExperience ?? this.therapistExperience,
      therapistRating: therapistRating ?? this.therapistRating,
      doctorNotes: doctorNotes ?? this.doctorNotes,
    );
  }
}