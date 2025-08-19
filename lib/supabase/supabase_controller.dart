import 'package:get/get.dart';
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
        .eq(DatabaseSchema.sessionTypeIsActive, true);
    var bookingList = SessionTypeModel.fromJsonList(response);
    return bookingList;
  }

}
