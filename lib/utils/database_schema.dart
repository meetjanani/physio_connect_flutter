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

  // City State Master Table
  static const String cityStateTable = "city_state";
  static const String cityStateId = "id";
  static const String cityStateName = "cityStateName";
  static const String cityStateDescription = "description";
  static const String cityStateIsActive = "isActive";

  // Area Master Table
  static const String areaTable = "area";
  static const String areaId = "id";
  static const String areaName = "areaName";
  static const String areaDescription = "description";
  static const String areaCityStateId = "cityStateId";
  static const String areaDoctorId = "doctorId";
  static const String areaIsActive = "isActive";

  static const String serviceAreasTable = "service_areas";
  static const String serviceAreasId = "id";
  static const String serviceAreasCityId = "cityId";
  static const String serviceAreasName = "name";
  static const String serviceAreasLatitude = "latitude";
  static const String serviceAreasLongitude = "longitude";
  static const String serviceAreasRadiusKm = "radiusKm";
  static const String serviceAreasIsActive = "isActive";
  static const String serviceAreasOrderBy = "orderBy";

  static const String doctorServiceAreasTable = "doctor_service_areas";
  static const String doctorServiceAreasId = "id";
  static const String doctorServiceAreasDoctorId = "doctorId";
  static const String doctorServiceAreasServiceAreaId = "serviceAreaId";
  static const String doctorServiceAreasIsActive = "isActive";

  //  Bookings table
  static const String bookingsTable = "bookings";
  static const String bookingsId = "id";
  static const String bookingsPaymentStatus = "paymentStatus";
  static const String bookingsPrice = "price";
  static const String bookingsUserId = "userId";
  static const String bookingsTimeSlotId = "timeSlotId";
  static const String bookingsDoctorId = "doctorId";
  static const String bookingsCityId = "cityId";
  static const String bookingsAreaId = "areaId";
  static const String bookingsServiceAreaId = "serviceAreaId";
  static const String bookingsCityName = "cityName";
  static const String bookingsAreaName = "areaName";
  static const String bookingsSessionTypeId = "sessionTypeId";
  static const String bookingsDate = "bookingDate";
  static const String bookingsStatus = "bookingStatus";
  static const String bookingsDoctorNotes = "doctorNotes";
  static const String bookingsPaymentId = "paymentId";
  static const String bookingsOrderId = "orderId";
  static const String bookingsSignature = "signature";
  static const String bookingsCreatedAt = "createdAt";
  static const String bookingsIsBulkAppointment = "isBulkAppointment";
  static const String bookingsBulkAppointmentId = "bulkAppointmentId";

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

  // Razorpay / Payment fields
  // Bookings Razorpay fields
  static const String bookingsRazorpayOrderId = "razorpayOrderId";

  static const String bookingsRazorpayPaymentId = "razorpayPaymentId";

  static const String bookingsRazorpaySignature = "razorpaySignature";

  static const String bookingsPaymentAmount = "paymentAmount";

  static const String bookingsDoctorAmount = "doctorAmount";

  static const String bookingsPlatformFeeAmount = "platformFeeAmount";

  static const String bookingsPaymentCurrency = "paymentCurrency";

  static const String bookingsPaymentVerifiedAt = "paymentVerifiedAt";

  static const String bookingsRazorpayTransferId = "razorpayTransferId";

  static const String bookingsTransferStatus = "transferStatus";

  // Doctor Razorpay Account fields
  static const String doctorRazorpayAccountId = "razorpayAccountId";

  static const String doctorRazorpayAccountStatus = "razorpayAccountStatus";

  static const String doctorRazorpayOnboardedAt = "razorpayOnboardedAt";
}
