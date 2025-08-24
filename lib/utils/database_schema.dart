

import 'package:get/get.dart';

class DatabaseSchema extends GetxController {
  static DatabaseSchema get to => Get.find();


  // Document name will be +91{10 digit MobileNumber}
  static const String usersTable = "users";
  static const String usersId = "id";
  static const String usersDoctorId = "doctorId";
  static const String userName = "name";
  static const String userMobileNumber = "mobileNumber";
  static const String usersUserType = "userType";
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
  static const String bookingsSessionTypeId = "sessionTypeId";
  static const String bookingsDate = "bookingDate";
  static const String bookingsCreatedAt = "createdAt";


  // Session Types table
  static const String sessionTypeTable = "session_type";
  static const String sessionTypeId = "id";
  static const String sessionTypeName = "name";
  static const String sessionTypeDescription = "description";
  static const String sessionTypeDurationMinutes = "duration";
  static const String sessionTypePrice = "price";
  static const String sessionTypeImageUrl = "imageUrl";
  static const String sessionTypeIsActive = "isActive";
  static const String sessionTypeOrderBy = "orderBy";

  // Time Slots table
  static const String timeSlotTable = "time_slot";
  static const String timeSlotId = "id";
  static const String timeSlotTime = "time";
  static const String timeSlotIsBooked = "isBooked";
  static const String timeSlotOrderBy = "orderBy";
  static const String timeSlotIsActive = "isActive";

  // Doctors table
  static const String doctorTable = "doctor";
  static const String doctorId = "id";
  static const String doctorName = "name";
  static const String doctorDegree = "degree";
  static const String doctorExperience = "experience";
  static const String doctorDrRegNumber = "drRegNumber";
  static const String doctorBiodata = "biodata";
  static const String doctorIsActive = "isActive";



  // common string
  static const String projectName = "PHYSIO CONNECT";

}