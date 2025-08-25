import 'package:get/get.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/model/time_slots_model.dart';
import 'package:physio_connect/utils/view_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/bookings_model.dart';
import '../model/session_type_model.dart';
import '../model/user_model_supabase.dart';
import '../route/route_module.dart';
import '../utils/database_schema.dart';
import '../utils/secure_storage/notification_service.dart';

class SupabaseController {
  static SupabaseController get to => Get.find();
  final notificationService = NotificationService();
  final SupabaseClient supabaseClient = Supabase.instance.client;

  Future<List<BookingsModel>> getUpComingBookings(int userId) async {
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final response = await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .select('*')
        .eq(DatabaseSchema.bookingsUserId, userId)
        .gte(DatabaseSchema.bookingsDate, today)
        .order(DatabaseSchema.bookingsId, ascending: true);
    var bookingList = BookingsModel.fromJsonList(response);
    return bookingList;
  }

  Future<void> updateFirebaseToken(int userId, String firebaseToken) async {
    if (userId > 0 && firebaseToken.isNotEmpty) {
      await supabaseClient
          .from(DatabaseSchema.usersTable)
          .update({DatabaseSchema.userFirebaseToken: firebaseToken})
          .eq(DatabaseSchema.usersId, userId)
          .select();
    }
  }

  // Get Master Data
  Future<List<SessionTypeModel>> getSessionTypeMaster() async {
    final response = await supabaseClient
        .from(DatabaseSchema.sessionTypeTable)
        .select('*')
        .eq(DatabaseSchema.sessionTypeIsActive, true)
        .order(DatabaseSchema.sessionTypeOrderBy, ascending: true);
    var bookingList = SessionTypeModel.fromJsonList(response);
    return bookingList;
  }

  // TODO: Add logic to fetch available time slots based on selected date from bookings table.
  Future<List<TimeSlotModel>> getTimeSlotsMaster() async {
    final response = await supabaseClient
        .from(DatabaseSchema.timeSlotTable)
        .select('*')
        .eq(DatabaseSchema.timeSlotIsActive, true)
        .order(DatabaseSchema.timeSlotOrderBy, ascending: true);
    var timeSlotList = TimeSlotModel.fromJsonList(response);
    return timeSlotList;
  }

  Future<void> createNewBooking(
    BookingsModel bookingsModel,
    int notificationUserId,
  ) async {
    var request = bookingsModel.toJson();
    request.remove('id');
     await Supabase.instance.client
        .from(DatabaseSchema.bookingsTable)
        .upsert([request])
        .select();

    await newBookingNotificationToAdmin(notificationUserId).then((result) {
      Get.back(result: true); // dismiss progress bar
      Get.showSuccessSnackbar('Your booking has been placed successfully.');
      Get.toNamed(AppPage.bookingConfirmation);
    });
  }

  Future<DoctorModel?> getDoctorById(int doctorId) async {
    final response = await supabaseClient
        .from(DatabaseSchema.doctorTable)
        .select('*')
        .eq(DatabaseSchema.doctorId, doctorId)
        .limit(1);
    if (response.isNotEmpty) {
      var doctor = DoctorModel.fromJson(response.first);
      return doctor;
    } else {
      return null;
    }
  }

  Future<void> newBookingNotificationToAdmin(int doctorId) async {
    try {
      final response = await Supabase.instance.client
          .from(DatabaseSchema.usersTable)
          .select('*')
          .eq(DatabaseSchema.usersId, doctorId)
          .eq(DatabaseSchema.usersUserType, "Doctor");

      var userList = (UserModelSupabase.fromJsonList(response)).where((it) =>
      it.firebaseToken != null && it.firebaseToken!.isNotEmpty).toList();
      // Use a proper async loop
      for (final adminUser in userList) {
        await notificationService.sendPushNotification(
          adminUser.firebaseToken!,
          "Yippee!!!, New Booking...",
          "New booking placed successfully.",
        );
      }
    } catch (e) {
      print('Error in newBookingNotificationToAdmin: $e');
    }
  }
}
