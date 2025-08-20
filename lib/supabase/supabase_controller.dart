import 'package:get/get.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/model/time_slots_model.dart';
import 'package:physio_connect/utils/view_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/bookings_model.dart';
import '../model/session_type_model.dart';
import '../utils/database_schema.dart';

class SupabaseController {
  static SupabaseController get to => Get.find();
  final SupabaseClient supabaseClient = Supabase.instance.client;

  Future<List<BookingsModel>> getUpComingBookings(int userId) async {
    final response = await supabaseClient
        .from(DatabaseSchema.bookingsTable)
        .select('*')
        .eq(DatabaseSchema.bookingsUserId, userId);
    var bookingList = BookingsModel.fromJsonList(response);
    return bookingList;
  }

  Future<void> updateFirebaseToken(int userId, String firebaseToken) async {
    await supabaseClient
        .from(DatabaseSchema.usersTable)
        .update({DatabaseSchema.userFirebaseToken: firebaseToken})
        .eq(DatabaseSchema.usersId, userId)
        .select();
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

  Future<void> createNewBooking(BookingsModel bookingsModel) async {
    var request = bookingsModel.toJson();
    request.remove('id');
    var response = await Supabase.instance.client.from(DatabaseSchema.bookingsTable).upsert([
      request,
    ]).select();
    // await newBookingNotificationToAdmin();
    Get.back(result: true); // dismiss progress bar
    // Get.back(result: true); // navigate back screen
    Get.showSuccessSnackbar('Your booking has been placed successfully.');
  }

  Future<DoctorModel?> getDoctorById(int doctorId) async {
    final response = await supabaseClient
        .from(DatabaseSchema.doctorTable)
        .select('*')
        .eq(DatabaseSchema.doctorId, doctorId).limit(1);
    if(response.isNotEmpty) {
      var doctor = DoctorModel.fromJson(response.first);
      return doctor;
    } else {
      return null;
    }
  }
}
