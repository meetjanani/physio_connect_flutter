

import 'package:get/get.dart';

class DatabaseSchema extends GetxController {
  static DatabaseSchema get to => Get.find();


  // Document name will be +91{10 digit MobileNumber}
  static const String usersTable = "users";
  static const String usersId = "id";
  static const String userName = "name";
  static const String userMobileNumber = "mobileNumber";
  static const String userIsAdmin = "isAdmin";
  static const String userFirebaseToken = "firebaseToken";
  static const String userCreateAt = "createAt";
  static const String userCityId = "cityId";
  static const String userCityName = "cityName";

  //  Bookings table
  static const String bookingsTable = "bookings";
  static const String bookingsId = "id";
  static const String bookingsUserId = "userId";
  static const String bookingsTimeSlotId = "timeSlotId";
  static const String bookingsDoctorId = "doctorId";
  static const String bookingsSessionId = "sessionId";
  static const String bookingsDate = "bookingDate";
  static const String bookingsCreatedAt = "createdAt";


  // common string
  static const String projectName = "PHYSIO CONNECT";

}