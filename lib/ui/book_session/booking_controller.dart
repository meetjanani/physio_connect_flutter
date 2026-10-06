// lib/ui/booking/booking_controller.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/model/city_state_model.dart';
import 'package:physio_connect/model/doctor_model.dart';
import 'package:physio_connect/utils/enum.dart';
import 'package:uuid/uuid.dart';

import '../../model/bookings_model.dart';
import '../../model/create_razorpay_order_model.dart';
import '../../model/area_model.dart';
import '../../model/session_type_model.dart';
import '../../model/time_slots_model.dart';
import '../../model/user_model_supabase.dart';
import '../../services/appointment_reminder_service.dart';
import '../../supabase/supabase_controller.dart';
import '../../utils/constants.dart';

class BookingController extends GetxController {
  static BookingController get to => Get.find();

  BookingController();

  /// Drops the current booking session and registers an empty controller.
  static void replaceWithFresh() {
    if (Get.isRegistered<BookingController>()) {
      Get.delete<BookingController>(force: true);
    }
    Get.put(BookingController(), permanent: true);
  }

  @override
  void onClose() {
    addressController.dispose();
    houseNameBlockNumberController.dispose();
    emailController.dispose();
    super.onClose();
  }

  // Add a TextEditingController for address if not present in controller
  final TextEditingController addressController = TextEditingController();
  final TextEditingController houseNameBlockNumberController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final RxString latitudeOfAddress = ''.obs;
  final RxString longitudeOfAddress = ''.obs;
  SupabaseController supabaseController = SupabaseController.to;

  final isLoading = false.obs;

  // Session Type
  final selectedSessionType = Rx<SessionTypeModel?>(null);
  bool get isSelectedOnline => selectedSessionType.value?.isOnline == true;
  final sessionTypes = <SessionTypeModel>[].obs;
  // Time slots data
  final selectedTimeSlot = Rx<TimeSlotModel?>(null);
  final bookingsModel = Rx<BookingsModel?>(null);
  final timeSlots = <TimeSlotModel>[].obs;

  /// Per-date resolved timeslot (`yyyy-MM-dd` -> slot).
  final timeSlotByDate = <String, TimeSlotModel>{}.obs;

  /// Dates where preferred timeslot is unavailable.
  final conflictDates = <String>{}.obs;

  final isCheckingConflicts = false.obs;

  final selectedDate = DateTime.now().add(const Duration(days: 1)).obs;
  final isBulkAppointment = false.obs;
  final bulkAppointmentCount = 1.obs;
  final recurrence = 'every_day'.obs;
  final appointmentDates = <DateTime>[].obs;
  String? bulkAppointmentId;
  final pendingBookingIds = <int>[].obs;
  final paymentFailureMessage = ''.obs;
  final createRazorPayOrderModel = Rx<CreateRazorPayOrderModel?>(null);

  void resetPendingPaymentAttempt() {
    pendingBookingIds.clear();
    paymentFailureMessage.value = '';
  }

  String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  bool get hasUnresolvedConflicts => conflictDates.isNotEmpty;

  bool get canContinueToPayment {
    if (selectedSessionType.value == null) return false;
    if (appointmentDates.isEmpty) return false;
    if (hasUnresolvedConflicts) return false;
    if (isCheckingConflicts.value) return false;
    for (final date in appointmentDates) {
      if (!timeSlotByDate.containsKey(dateKey(date))) return false;
    }
    return true;
  }

  void clearPerDateTimeSlots() {
    timeSlotByDate.clear();
    conflictDates.clear();
  }

  List<int>? _configuredTimeSlotIds() {
    final configured = selectedDoctor.value?.timeSlotId
        ?.split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList();
    if (configured == null || configured.isEmpty) return null;
    return configured;
  }

  void configureAppointmentDates() {
    resetPendingPaymentAttempt();
    final count = bulkAppointmentCount.value.clamp(1, 100);
    bulkAppointmentCount.value = count;
    isBulkAppointment.value = count >= 2;
    final step = count >= 2 ? _recurrenceStepDays() : 1;
    final start = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );
    appointmentDates.assignAll(
      List.generate(count, (index) => start.add(Duration(days: index * step))),
    );
    // Re-check preferred time across the new date set.
    if (selectedTimeSlot.value != null) {
      checkConflictsAcrossDates();
    } else {
      clearPerDateTimeSlots();
    }
  }

  int _recurrenceStepDays() {
    return recurrence.value == 'alternative_day'
        ? 2
        : recurrence.value == 'every_2_day'
        ? 3
        : 1;
  }

  void setBulkAppointmentCountValue(int count) {
    if (count < 1 || count > 100) return;
    bulkAppointmentCount.value = count;
    isBulkAppointment.value = count >= 2;
    if (count < 2) {
      recurrence.value = 'every_day';
    }
    if (appointmentDates.isNotEmpty) {
      selectedDate.value = DateTime(
        appointmentDates.first.year,
        appointmentDates.first.month,
        appointmentDates.first.day,
      );
    }
    configureAppointmentDates();
  }

  void adjustBulkAppointmentCount(int delta) {
    setBulkAppointmentCountValue(bulkAppointmentCount.value + delta);
  }

  void setRecurrence(String value) {
    recurrence.value = value;
    configureAppointmentDates();
  }

  /// Updates [index] and regenerates all following dates using the current
  /// recurrence step (every day / alternate / every 2 days).
  /// Returns `true` when the first session date changed (time slots should refresh).
  bool updateAppointmentDate(int index, DateTime date) {
    resetPendingPaymentAttempt();
    if (index < 0 || index >= appointmentDates.length) return false;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isBefore(todayDate)) return false;

    if (index > 0) {
      final previous = appointmentDates[index - 1];
      final previousDate = DateTime(
        previous.year,
        previous.month,
        previous.day,
      );
      if (!normalized.isAfter(previousDate)) return false;
    }

    final dates = appointmentDates.toList();
    dates[index] = normalized;
    final step = dates.length >= 2 ? _recurrenceStepDays() : 1;
    for (var i = index + 1; i < dates.length; i++) {
      dates[i] = dates[i - 1].add(Duration(days: step));
    }
    appointmentDates.assignAll(dates);

    if (index == 0) {
      selectedDate.value = normalized;
      return true;
    }

    return false;
  }

  /// Sets preferred timeslot and checks availability on every selected date.
  Future<void> selectPreferredTimeSlot(TimeSlotModel slot) async {
    selectedTimeSlot.value = slot;
    await checkConflictsAcrossDates();
  }

  /// For each appointment date, prefer [selectedTimeSlot] when free; otherwise
  /// mark the date as a conflict until the user picks an alternate.
  Future<void> checkConflictsAcrossDates() async {
    final preferred = selectedTimeSlot.value;
    final dates = appointmentDates.toList();
    if (preferred == null || dates.isEmpty) {
      clearPerDateTimeSlots();
      return;
    }

    isCheckingConflicts.value = true;
    try {
      final doctorUserId = selectedDoctor.value?.userId ?? 0;
      final configuredIds = _configuredTimeSlotIds();
      final results = await Future.wait(
        dates.map(
          (date) => supabaseController.getTimeSlotsMaster(
            date,
            doctorUserId,
            timeSlotIds: configuredIds,
          ),
        ),
      );

      final nextSlots = <String, TimeSlotModel>{};
      final nextConflicts = <String>{};

      for (var i = 0; i < dates.length; i++) {
        final key = dateKey(dates[i]);
        final daySlots = results[i];
        final match = daySlots.cast<TimeSlotModel?>().firstWhere(
          (s) => s?.id == preferred.id,
          orElse: () => null,
        );
        final isBooked = match == null || (match.isBooked ?? false);
        if (isBooked) {
          nextConflicts.add(key);
        } else {
          nextSlots[key] = match;
        }
      }

      timeSlotByDate
        ..clear()
        ..addAll(nextSlots);
      conflictDates
        ..clear()
        ..addAll(nextConflicts);
      timeSlotByDate.refresh();
      conflictDates.refresh();
    } finally {
      isCheckingConflicts.value = false;
    }
  }

  /// Saves an alternate timeslot for a single conflict date.
  void resolveConflictForDate(DateTime date, TimeSlotModel slot) {
    final key = dateKey(date);
    timeSlotByDate[key] = slot;
    conflictDates.remove(key);
    timeSlotByDate.refresh();
    conflictDates.refresh();
    resetPendingPaymentAttempt();
  }

  TimeSlotModel? timeSlotForDate(DateTime date) =>
      timeSlotByDate[dateKey(date)];

  bool isConflictDate(DateTime date) => conflictDates.contains(dateKey(date));

  Future<List<TimeSlotModel>> loadSlotsForDate(DateTime date) async {
    return supabaseController.getTimeSlotsMaster(
      date,
      selectedDoctor.value?.userId ?? 0,
      timeSlotIds: _configuredTimeSlotIds(),
    );
  }

  UserModelSupabase? userModelSupabase;
  @override
  Future<void> onInit() async {
    super.onInit();
    isLoading.value = true;
    userModelSupabase = await UserModelSupabase.getFromSecureStorage();
    prefillEmailFromProfile();
    isLoading.value = false;
  }

  Future<void> initializeEmailFromProfile() async {
    userModelSupabase ??= await UserModelSupabase.getFromSecureStorage();
    prefillEmailFromProfile();
  }

  void prefillEmailFromProfile() {
    if (emailController.text.trim().isEmpty) {
      emailController.text = userModelSupabase?.guestEmail?.trim() ?? '';
    }
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
    // Keep preferred slot if still present after first-date refresh;
    // conflict check decides per-date mapping.
    final previousPreferredId = selectedTimeSlot.value?.id;
    selectedTimeSlot.value = null;
    clearPerDateTimeSlots();
    try {
      final response = await supabaseController.getTimeSlotsMaster(
        selectedDate.value,
        selectedDoctor.value?.userId ?? 0,
        timeSlotIds: _configuredTimeSlotIds(),
      );
      timeSlots.addAll(response);
      if (previousPreferredId != null) {
        final stillAvailable = timeSlots.cast<TimeSlotModel?>().firstWhere(
          (s) => s?.id == previousPreferredId && !(s?.isBooked ?? true),
          orElse: () => null,
        );
        if (stillAvailable != null) {
          await selectPreferredTimeSlot(stillAvailable);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<CreateRazorPayOrderModel?> createPendingBookingBeforePayment() async {
    if (selectedSessionType.value == null) return null;
    if (!canContinueToPayment) return null;
    isLoading.value = true;

    try {
      await initializeEmailFromProfile();
      final bookingEmail = emailController.text.trim();
      final profileEmail = userModelSupabase?.guestEmail?.trim() ?? '';
      if (bookingEmail.isNotEmpty && bookingEmail != profileEmail) {
        final user = userModelSupabase;
        if (user == null || user.id <= 0) {
          throw StateError(
            'Could not identify your profile to save the email.',
          );
        }
        await supabaseController.updateUserEmail(user.id, bookingEmail);
        user.guestEmail = bookingEmail;
        await user.saveToSecureStorage();
      }

      final doctorModel =
          selectedDoctor.value ?? await DoctorModel.getFromSecureStorage();
      final doctorJson = jsonEncode(doctorModel?.toJson() ?? {});
      final sessionType = selectedSessionType.value!;
      final sessionTypeJson = jsonEncode(sessionType.toJson());
      final patientJson = jsonEncode(userModelSupabase?.toJson() ?? {});

      final dates = appointmentDates.isEmpty
          ? [
              DateTime(
                selectedDate.value.year,
                selectedDate.value.month,
                selectedDate.value.day,
              ),
            ]
          : appointmentDates.toList();

      for (final date in dates) {
        if (timeSlotForDate(date) == null) return null;
      }

      if (dates.length > 1) {
        bulkAppointmentId = const Uuid().v4();
      }
      final groupId = dates.length > 1 ? bulkAppointmentId : null;
      final bookings = dates.map((date) {
        final slot = timeSlotForDate(date)!;
        return BookingsModel(
          id: 0,
          userId: userModelSupabase?.id ?? 0,
          bookingStatus: BookingStatus.pending.name,
          timeSlotId: slot.id,
          timeSlotJson: jsonEncode(slot.toJson()),
          doctorId: doctorModel?.userId ?? selectedDoctor.value?.userId ?? 0,
          doctorJson: doctorJson,
          patientJson: patientJson,
          cityStateJson: selectedCity.value?.toJson().toString(),
          areaJson: selectedArea.value?.toJson().toString(),
          sessionTypeId: sessionType.id,
          sessionTypeJson: sessionTypeJson,
          price: sessionType.price,
          paymentStatus: PaymentStatus.pending.name,
          paymentId: null,
          orderId: null,
          signature: null,
          doctorNotes: 'No additional notes provided.',
          address: sessionType.isOnline
              ? 'Online session'
              : "${houseNameBlockNumberController.text}\n${addressController.text}",
          latLong: sessionType.isOnline
              ? ''
              : "${latitudeOfAddress.value}${LAT_LONG_SEPRATOR}${longitudeOfAddress.value}",
          guestEmail: bookingEmail.isEmpty ? null : bookingEmail,
          bookingDate: dateKey(date),
          createdAt: DateTime.now().toString(),
          isBulkAppointment: groupId != null,
          bulkAppointmentId: groupId,
        );
      }).toList();
      bookingsModel.value = bookings.first;
      final bookingIds = await supabaseController.createNewBookings(bookings);
      pendingBookingIds.assignAll(bookingIds);
      final razorpayOrder = await supabaseController
          .callCreateRazorPayOrderForBookings(
            bookingIds: bookingIds,
            userId: userModelSupabase?.id ?? 0,
            isBulkAppointment: groupId != null,
            bulkAppointmentId: groupId,
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

  /// areaId -> assigned doctor (one doctor per area for list UI).
  final areaDoctorByAreaId = <int, DoctorModel>{}.obs;
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
    areaDoctorByAreaId.clear();
    selectedArea.value = null;
    isLoading.value = true;
    try {
      final areas = await supabaseController.getServiceAreas(
        selectedCity.value!.id,
      );
      serviceAreas.assignAll(areas);

      final doctorIds = areas
          .map((a) => a.doctorId ?? 0)
          .where((id) => id > 0)
          .toList();
      if (doctorIds.isNotEmpty) {
        final doctors = await supabaseController.getDoctorsByIds(doctorIds);
        final byId = {for (final d in doctors) (d.id ?? 0): d};
        final mapped = <int, DoctorModel>{};
        for (final area in areas) {
          final doctorId = area.doctorId ?? 0;
          final doctor = byId[doctorId];
          if (doctor != null) {
            mapped[area.id] = doctor;
          }
        }
        areaDoctorByAreaId.assignAll(mapped);
      }

      if (areas.length == 1) {
        selectedArea.value = areas.first;
      } else {
        selectedArea.value = null;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Not In Use
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
    areaDoctorByAreaId.clear();
    areaDoctors.clear();
  }

  /// Schedules local alarms only if reminder permission is already granted.
  Future<void> scheduleLocalRemindersIfAllowed() async {
    final dates = appointmentDates.isEmpty
        ? [selectedDate.value]
        : appointmentDates.toList();
    final ids = pendingBookingIds.toList();
    final sessionName = selectedSessionType.value?.name ?? 'Physio session';
    final online = isSelectedOnline;
    for (var i = 0; i < dates.length; i++) {
      final date = dates[i];
      final slot = timeSlotForDate(date) ?? selectedTimeSlot.value;
      final bookingId = i < ids.length
          ? ids[i]
          : (bookingsModel.value?.id ?? 0);
      if (bookingId <= 0) continue;
      await AppointmentReminderService.instance.scheduleSessionReminders(
        bookingId: bookingId,
        sessionStart: AppointmentReminderService.combineDateAndSlot(
          date,
          slot?.time ?? '09:00',
        ),
        sessionLabel: online ? '$sessionName — join from the app' : sessionName,
        includeJoinSoon: online,
      );
    }
  }

  /// Sets city / area / assigned doctor and loads that doctor's session types.
  Future<void> startSessionBookingForDoctor({
    required DoctorModel doctor,
    required AreaModel area,
    required CityStateModel city,
  }) async {
    selectedCity.value = city;
    selectedArea.value = area;
    selectedDoctor.value = doctor;
    await getSessionTypesMaster();
  }
}
