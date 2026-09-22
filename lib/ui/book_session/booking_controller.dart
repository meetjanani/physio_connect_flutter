// lib/ui/booking/booking_controller.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/model/city_state_model.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/utils/enum.dart';
import 'package:physio_connect/utils/view_extension.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../model/bookings_model.dart';
import '../../model/create_razorpay_order_model.dart';
import '../../model/area_model.dart';
import '../../model/session_type_model.dart';
import '../../model/time_slots_model.dart';
import '../../model/user_model_supabase.dart';
import '../../supabase/supabase_controller.dart';
import '../../utils/app_shared_preference.dart';
import '../../utils/constants.dart';

class BookingController extends GetxController {
  static BookingController get to => Get.find();

  BookingController();
  // Add a TextEditingController for address if not present in controller
  final TextEditingController addressController = TextEditingController();
  final TextEditingController houseNameBlockNumberController =
      TextEditingController();
  final RxString latitudeOfAddress = ''.obs;
  final RxString longitudeOfAddress = ''.obs;
  SupabaseController supabaseController = SupabaseController.to;

  final isLoading = false.obs;

  // Session Type
  final selectedSessionType = Rx<SessionTypeModel?>(null);
  final sessionTypes = <SessionTypeModel>[].obs;
  // Time slots data
  final selectedTimeSlot = Rx<TimeSlotModel?>(null);
  final bookingsModel = Rx<BookingsModel?>(null);
  final timeSlots = <TimeSlotModel>[].obs;

  final selectedDate = DateTime.now().obs;
  final razorpayPaymentId = ''.obs;
  var bookingId = 0;
  final createRazorPayOrderModel = Rx<CreateRazorPayOrderModel?>(null);

  UserModelSupabase? userModelSupabase;
  @override
  Future<void> onInit() async {
    super.onInit();
    isLoading.value = true;
    userModelSupabase = await UserModelSupabase.getFromSecureStorage();
    await getSessionTypesMaster();
    await getTimeSlotsMaster();
    isLoading.value = false;
  }

  // Load master data
  Future<void> getSessionTypesMaster() async {
    sessionTypes.clear();
    var response = await supabaseController.getSessionTypeMaster();
    sessionTypes.addAll(response);
  }

  // Load master data
  Future<void> getTimeSlotsMaster() async {
    timeSlots.clear();
    selectedTimeSlot.value = null;
    var response = await supabaseController.getTimeSlotsMaster(
      selectedDate.value,
    );
    timeSlots.addAll(response);
  }

  void createAppointment(
    PaymentSuccessResponse paymentResponse,
    PaymentStatus paymentStatus,
  ) async {
    isLoading.value = true;
    final doctorModel =
        selectedDoctor.value ?? await DoctorModel.getFromSecureStorage();
    final doctorJson = jsonEncode(doctorModel?.toJson() ?? {});
    final timeslotJson = jsonEncode(selectedTimeSlot.value?.toJson() ?? {});
    final sessionTypeJson = jsonEncode(
      selectedSessionType.value?.toJson() ?? {},
    );
    final patientJson = jsonEncode(userModelSupabase?.toJson() ?? {});

    final notificationDoctorId =
        doctorModel?.userId ?? selectedDoctor.value?.userId ?? 0;
    if (notificationDoctorId > 0) {
      await supabaseController.sentNotification(
        notificationDoctorId,
        "Yippee!!!, New Booking...",
        "New booking placed successfully.",
      );
    }

    bookingsModel.value = BookingsModel(
      id: 0,
      userId: userModelSupabase?.id ?? 0,
      bookingStatus: BookingStatus.booked.name,
      timeSlotId: selectedTimeSlot.value?.id ?? 1,
      timeSlotJson: timeslotJson,
      doctorId: doctorModel?.id ?? selectedDoctor.value?.id ?? 0,
      cityStateJson: selectedCity.value?.toJson().toString(),
      areaJson: selectedArea.value?.toJson().toString(),
      doctorJson: doctorJson,
      sessionTypeId: selectedSessionType.value?.id ?? 1,
      price: selectedSessionType.value?.price ?? 1,
      sessionTypeJson: sessionTypeJson,
      patientJson: patientJson,
      paymentStatus: paymentStatus.name,
      paymentId: paymentResponse.paymentId!,
      orderId: paymentResponse.orderId,
      signature: paymentResponse.signature,
      doctorNotes: "No additional notes provided.",
      address:
          "${houseNameBlockNumberController.text}\n${addressController.text}",
      latLong:
          "${latitudeOfAddress.value}${LAT_LONG_SEPRATOR}${longitudeOfAddress.value}",
      bookingDate: DateFormat('yyyy-MM-dd').format(selectedDate.value),
      createdAt: DateTime.now().toString(),
    );
    await supabaseController.createNewBooking(
      bookingsModel.value!,
      notificationDoctorId,
    );
    isLoading.value = false;

    // In a real app, this would create the appointment in your database
    final appointmentId = Uuid().v4();

    // Example implementation:
    // final appointment = booking_model.dart(
    //   appointmentId: appointmentId,
    //   userId: 'current-user-id', // Get from auth service
    //   therapistId: 'assigned-therapist-id',
    //   sessionTypeId: selectedSessionType.value!.sessionTypeId,
    //   date: DateFormat('yyyy-MM-dd').format(selectedDate.value),
    //   startTime: selectedTimeSlot.value,
    //   endTime: calculateEndTime(selectedTimeSlot.value, selectedSessionType.value!.durationMinutes),
    //   status: 'booked',
    //   createdAt: DateTime.now(),
    // );

    // Create payment record
    // final payment = PaymentModel(
    //   paymentId: Uuid().v4(),
    //   appointmentId: appointmentId,
    //   amount: selectedSessionType.value!.price,
    //   razorpayPaymentId: razorpayPaymentId.value,
    //   status: 'completed',
    //   timestamp: DateTime.now(),
    // );

    // Save to database
    // databaseService.saveAppointment(appointment);
    // databaseService.savePayment(payment);

    print('Appointment created with ID: $appointmentId');
  }

  Future<CreateRazorPayOrderModel?> createPendingBookingBeforePayment() async {
    isLoading.value = true;

    try {
      final doctorModel =
          selectedDoctor.value ?? await DoctorModel.getFromSecureStorage();
      final doctorJson = jsonEncode(doctorModel?.toJson() ?? {});
      final timeslotJson = jsonEncode(selectedTimeSlot.value?.toJson() ?? {});
      final sessionTypeJson = jsonEncode(
        selectedSessionType.value?.toJson() ?? {},
      );
      final patientJson = jsonEncode(userModelSupabase?.toJson() ?? {});

      bookingsModel.value = BookingsModel(
        id: 0,
        userId: userModelSupabase?.id ?? 0,
        bookingStatus: BookingStatus.pending.name,
        timeSlotId: selectedTimeSlot.value?.id ?? 1,
        timeSlotJson: timeslotJson,
        doctorId: doctorModel?.userId ?? selectedDoctor.value?.id ?? 0,
        cityStateJson: selectedCity.value?.toJson().toString(),
        areaJson: selectedArea.value?.toJson().toString(),
        doctorJson: doctorJson,
        sessionTypeId: selectedSessionType.value?.id ?? 1,
        price: selectedSessionType.value?.price ?? 1,
        sessionTypeJson: sessionTypeJson,
        patientJson: patientJson,
        paymentStatus: PaymentStatus.pending.name,
        paymentId: null,
        orderId: null,
        signature: null,
        doctorNotes: 'No additional notes provided.',
        address:
            "${houseNameBlockNumberController.text}\n${addressController.text}",
        latLong:
            "${latitudeOfAddress.value}${LAT_LONG_SEPRATOR}${longitudeOfAddress.value}",
        bookingDate: DateFormat('yyyy-MM-dd').format(selectedDate.value),
        createdAt: DateTime.now().toString(),
      );

      final notificationDoctorId =
          doctorModel?.userId ?? selectedDoctor.value?.userId ?? 0;
      bookingId = await supabaseController.createNewBooking(
        bookingsModel.value!,
        notificationDoctorId,
      );
      var razorpayOrder = await supabaseController
          .callCreateRazorPayOrderSBEdgeFunction(
            bookingId,
            userModelSupabase?.id ?? 0,
          );
      createRazorPayOrderModel.value = razorpayOrder;
      return razorpayOrder;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBookingPaymentStatusAfterSuccess({
    required PaymentSuccessResponse paymentResponse,
  }) async {
    if (bookingsModel.value == null) {
      throw Exception('No pending booking exists to update.');
    }

    bookingsModel.value = BookingsModel(
      id: bookingsModel.value!.id,
      userId: bookingsModel.value!.userId,
      bookingStatus: BookingStatus.booked.name,
      timeSlotId: bookingsModel.value!.timeSlotId,
      timeSlotJson: bookingsModel.value!.timeSlotJson,
      doctorId: bookingsModel.value!.doctorId,
      cityStateJson: selectedCity.value?.toJson().toString(),
      areaJson: selectedArea.value?.toJson().toString(),
      doctorJson: bookingsModel.value!.doctorJson,
      sessionTypeId: bookingsModel.value!.sessionTypeId,
      price: bookingsModel.value!.price,
      sessionTypeJson: bookingsModel.value!.sessionTypeJson,
      patientJson: bookingsModel.value!.patientJson,
      paymentStatus: PaymentStatus.paid.name,
      paymentId: paymentResponse.paymentId,
      orderId: paymentResponse.orderId,
      signature: paymentResponse.signature,
      doctorNotes: bookingsModel.value!.doctorNotes,
      address: bookingsModel.value!.address,
      latLong: bookingsModel.value!.latLong,
      bookingDate: bookingsModel.value!.bookingDate,
      createdAt: bookingsModel.value!.createdAt,
    );

    await supabaseController.createNewBooking(
      bookingsModel.value!,
      bookingsModel.value!.doctorId,
    );
  }

  Future<void> updateBookingPaymentStatusAfterFailure() async {
    if (bookingsModel.value == null) {
      return;
    }

    bookingsModel.value = BookingsModel(
      id: bookingsModel.value!.id,
      userId: bookingsModel.value!.userId,
      bookingStatus: BookingStatus.cancelled.name,
      timeSlotId: bookingsModel.value!.timeSlotId,
      timeSlotJson: bookingsModel.value!.timeSlotJson,
      doctorId: bookingsModel.value!.doctorId,
      areaJson: bookingsModel.value!.areaJson,
      doctorJson: bookingsModel.value!.doctorJson,
      sessionTypeId: bookingsModel.value!.sessionTypeId,
      price: bookingsModel.value!.price,
      sessionTypeJson: bookingsModel.value!.sessionTypeJson,
      patientJson: bookingsModel.value!.patientJson,
      paymentStatus: PaymentStatus.failed.name,
      paymentId: null,
      orderId: null,
      signature: null,
      doctorNotes: bookingsModel.value!.doctorNotes,
      address: bookingsModel.value!.address,
      latLong: bookingsModel.value!.latLong,
      bookingDate: bookingsModel.value!.bookingDate,
      createdAt: bookingsModel.value!.createdAt,
    );

    await supabaseController.createNewBooking(
      bookingsModel.value!,
      bookingsModel.value!.doctorId,
    );
  }

  String calculateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final startDateTime = DateTime(2023, 1, 1, hour, minute);
    final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));

    return '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
  }

  // --------------------------------------------------------------------------
  // NEW: Service coverage flow added in this update (keep this at the end)
  // --------------------------------------------------------------------------
  final serviceCities = <CityStateModel>[].obs;
  final serviceAreas = <AreaModel>[].obs;
  final areaDoctors = <DoctorModel>[].obs;
  final selectedCity = Rx<CityStateModel?>(null);
  final selectedArea = Rx<AreaModel?>(null);
  final selectedDoctor = Rx<DoctorModel?>(null);

  Future<void> loadServiceCities() async {
    isLoading.value = true;
    try {
      final cities = await supabaseController.getCityState();
      serviceCities.assignAll(cities);
      if (serviceCities.length == 1) {
        selectedCity.value = serviceCities.first;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadServiceAreasForSelectedCity() async {
    serviceAreas.clear();
    selectedArea.value = null;
    isLoading.value = true;
    try {
      final areas = await supabaseController.getServiceAreas(
        selectedCity.value!.id,
      );
      serviceAreas.assignAll(areas);
      if (areas.length == 1) {
        selectedArea.value = areas.first;
      } else {
        selectedArea.value = null;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDoctorsForSelectedArea() async {
    if (selectedArea.value == null) {
      areaDoctors.clear();
      return;
    }
    isLoading.value = true;
    try {
      final doctors = await supabaseController.getDoctorsForArea(
        selectedArea.value!.id,
      );
      areaDoctors.assignAll(doctors);
      if (doctors.length == 1) {
        selectedDoctor.value = doctors.first;
      } else {
        selectedDoctor.value = null;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void clearCoverageSelection() {
    selectedCity.value = null;
    selectedArea.value = null;
    selectedDoctor.value = null;
    serviceAreas.clear();
    areaDoctors.clear();
  }
}
