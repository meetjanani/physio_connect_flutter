
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/database_schema.dart';

class SupabaseController {
  static SupabaseController get to => Get.find();
  final SupabaseClient supabaseClient = Supabase.instance.client;
/*
  Future<List<BookingModel>> getUpComingBookings(int userId) async {
    final response = await Supabase.instance.client
        .from(DatabaseSchema.bookingsTable)
        .select('*');
    var bookingList = BookingModel.fromJsonList(response);
    return bookingList;
  }*/

  Future<void> updateFirebaseToken(int userId, String firebaseToken) async {
    await supabaseClient
        .from(DatabaseSchema.usersTable)
        .update({DatabaseSchema.userFirebaseToken: firebaseToken})
        .eq(DatabaseSchema.usersId, userId)
        .select();
  }

}