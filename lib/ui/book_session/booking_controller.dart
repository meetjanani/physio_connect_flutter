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
  final isBulkAppointment = false.obs;
  final bulkAppointmentCount = 1.obs;
  final recurrence = 'every_day'.obs;
  final appointmentDates = <DateTime>[].obs;
  String? bulkAppointmentId;
  final razorpayPaymentId = ''.obs;
  var bookingId = 0;
  final pendingBookingIds = <int>[].obs;
  final createRazorPayOrderModel = Rx<CreateRazorPayOrderModel?>(null);

  void configureAppointmentDates() {
    final count = isBulkAppointment.value ? bulkAppointmentCount.value : 1;
    final step = recurrence.value == 'alternative_day'
        ? 2
        : recurrence.value == 'every_2_day'
        ? 3
        : 1;
    appointmentDates.assignAll(
      List.generate(
        count,
        (index) => DateTime(
          selectedDate.value.year,
          selectedDate.value.month,
          selectedDate.value.day + (index * step),
        ),
      ),
    );
  }

  void setBulkAppointmentEnabled(bool enabled) {
    isBulkAppointment.value = enabled;
    if (!enabled) {
      bulkAppointmentCount.value = 1;
      recurrence.value = 'every_day';
    }
    configureAppointmentDates();
  }

  void setBulkAppointmentCount(String value) {
    final count = int.tryParse(value);
    if (count == null || count < 2 || count > 100) return;
    bulkAppointmentCount.value = count;
    configureAppointmentDates();
  }

  void setRecurrence(String value) {
    recurrence.value = value;
    configureAppointmentDates();
  }

  void updateAppointmentDate(int index, DateTime date) {
    if (index < 0 || index >= appointmentDates.length) return;
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isBefore(DateTime.now())) return;
    final dates = appointmentDates.toList()..[index] = normalized;
    appointmentDates.assignAll(dates);
  }

  UserModelSupabase? userModelSupabase;
  @override
  Future<void> onInit() async {
    super.onInit();
    isLoading.value = true;
    userModelSupabase = await UserModelSupabase.getFromSecureStorage();
    isLoading.value = false;
  }

  // Load master data
  Future<void> getSessionTypesMaster() async {
    isLoading.value = true;
    sessionTypes.clear();
    try {
      final configuredSessionTypeIds = selectedDoctor.value?.sessionTypeId
          ?.split(',')
          .map((value) => int.tryParse(value.trim()))
          .whereType<int>()
          .where((id) => id > 0)
          .toSet()
          .toList();
      final response = await supabaseController.getSessionTypeMaster(
        sessionTypeIds: configuredSessionTypeIds,
      );
      sessionTypes.addAll(response);
    } finally {
      isLoading.value = false;
    }
  }

  // Load master data
  Future<void> getTimeSlotsMaster() async {
    isLoading.value = true;
    timeSlots.clear();
    selectedTimeSlot.value = null;
    try {
      final configuredTimeSlotIds = selectedDoctor.value?.timeSlotId
          ?.split(',')
          .map((value) => int.tryParse(value.trim()))
          .whereType<int>()
          .where((id) => id > 0)
          .toSet()
          .toList();
      final response = await supabaseController.getTimeSlotsMaster(
        selectedDate.value,
        selectedDoctor.value?.userId ?? 0,
        timeSlotIds: configuredTimeSlotIds,
      );
      timeSlots.addAll(response);
    } finally {
      isLoading.value = false;
    }
  }

  void createAppointment(
    PaymentSuccessResponse paymentResponse,
    PaymentStatus paymentStatus,
  ) async {
    isLoading.value = true;
    final sessionType = selectedSessionType.value;
    if (sessionType == null) {
      isLoading.value = false;
      showErrorSnackbar(
        'Please select a session type before completing payment.',
      );
      return;
    }

    final doctorModel =
        selectedDoctor.value ?? await DoctorModel.getFromSecureStorage();
    final doctorJson = jsonEncode(doctorModel?.toJson() ?? {});
    final timeslotJson = jsonEncode(selectedTimeSlot.value?.toJson() ?? {});
    final sessionTypeJson = jsonEncode(sessionType.toJson());
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
      bookingStatus: BookingStatus.confirmed.name,
      timeSlotId: selectedTimeSlot.value?.id ?? 1,
      timeSlotJson: timeslotJson,
      doctorId: doctorModel?.id ?? selectedDoctor.value?.id ?? 0,
      cityStateJson: selectedCity.value?.toJson().toString(),
      areaJson: selectedArea.value?.toJson().toString(),
      doctorJson: doctorJson,
      sessionTypeId: sessionType.id,
      price: sessionType.price,
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
      final sessionType = selectedSessionType.value;
      if (sessionType == null) {
        showErrorSnackbar(
          'Please select a session type before proceeding to payment.',
        );
        return null;
      }

      final doctorModel =
          selectedDoctor.value ?? await DoctorModel.getFromSecureStorage();
      final doctorJson = jsonEncode(doctorModel?.toJson() ?? {});
      final timeslotJson = jsonEncode(selectedTimeSlot.value?.toJson() ?? {});
      final sessionTypeJson = jsonEncode(sessionType.toJson());
      final patientJson = jsonEncode(userModelSupabase?.toJson() ?? {});

      final dates = appointmentDates.isEmpty
          ? [DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day)]
          : appointmentDates.toList();
      if (dates.length > 1 && bulkAppointmentId == null) {
        bulkAppointmentId = const Uuid().v4();
      }
      final groupId = dates.length > 1 ? bulkAppointmentId : null;
      final bookings = dates.map((date) => BookingsModel(
        id: 0,
        userId: userModelSupabase?.id ?? 0,
        bookingStatus: BookingStatus.pending.name,
        timeSlotId: selectedTimeSlot.value?.id ?? 1,
        timeSlotJson: timeslotJson,
        doctorId: doctorModel?.id ?? selectedDoctor.value?.id ?? 0,
        cityStateJson: selectedCity.value?.toJson().toString(),
        areaJson: selectedArea.value?.toJson().toString(),
        doctorJson: doctorJson,
        sessionTypeId: sessionType.id,
        price: sessionType.price,
        sessionTypeJson: sessionTypeJson,
        patientJson: patientJson,
        paymentStatus: PaymentStatus.pending.name,
        paymentId: null,
        orderId: null,
        signature: null,
        doctorNotes: 'No additional notes provided.',
        address: "${houseNameBlockNumberController.text}\n${addressController.text}",
        latLong: "${latitudeOfAddress.value}${LAT_LONG_SEPRATOR}${longitudeOfAddress.value}",
        bookingDate: DateFormat('yyyy-MM-dd').format(date),
        createdAt: DateTime.now().toString(),
        isBulkAppointment: groupId != null,
        bulkAppointmentId: groupId,
      )).toList();
      bookingsModel.value = bookings.first;
      final notificationDoctorId = doctorModel?.userId ?? selectedDoctor.value?.userId ?? 0;
      final bookingIds = await supabaseController.createNewBookings(
        bookings,
        notificationDoctorId,
      );
      pendingBookingIds.assignAll(bookingIds);
      bookingId = bookingIds.first;
      var razorpayOrder = await supabaseController.callCreateRazorPayOrderForBookings(
        bookingIds,
        userModelSupabase?.id ?? 0,
      );
      createRazorPayOrderModel.value = razorpayOrder;
      return razorpayOrder;
    } finally {
      isLoading.value = false;
    }
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
