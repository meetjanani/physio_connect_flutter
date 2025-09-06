// lib/ui/booking/history/booking_history_controller.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/utils/view_extension.dart';

import '../../model/bookings_model.dart';
import '../../model/user_model_supabase.dart';
import '../../supabase/supabase_controller.dart';
import '../../utils/enum.dart';

class BookingHistoryController extends GetxController {
  static BookingHistoryController get to => Get.put(BookingHistoryController());

  final isLoading = true.obs;
  final isLoadingDetails = false.obs;

  // Date filter
  final fromDate = DateTime.now().subtract(Duration(days: 7)).obs;
  final toDate = DateTime.now().add(Duration(days: 7)).obs;

  // Appointments
  final selectedAppointment = Rx<BookingsModel?>(null);

  SupabaseController supabaseController =
      SupabaseController.to;
  UserModelSupabase? userModelSupabase;
  RxList<BookingsModel> upComingBookings = RxList();
  RxBool isDoctor = false.obs;
  final therapistsImage = "https://randomuser.me/api/portraits/women/44.jpg";

  @override
  Future<void> onInit() async {
    super.onInit();
    userModelSupabase = await UserModelSupabase.getFromSecureStorage();
    isDoctor.value = userModelSupabase?.userType?.toLowerCase() == UserType.doctor.name;
    getFilteredBookings();
  }

  Future<void> getFilteredBookings() async {
    if (userModelSupabase?.id != null) {
      isLoading.value = true;
      upComingBookings.clear();
      var response = await supabaseController.getFilteredBookings(userModelSupabase?.id ?? 0, fromDate.value, toDate.value, isDoctor.value);
      upComingBookings.addAll(response);
      isLoading.value = false;
      showSuccessSnackbar("${upComingBookings.value.length}");
    }
  }

  Future<void> updateDoctorNote(BookingsModel doctorNotes) async {
    if (userModelSupabase?.id != null) {
      isLoading.value = true;
      var response = await supabaseController.updateBookingStatus(doctorNotes?.id ?? 0, doctorNotes);
      isLoading.value = false;
    }
  }

  Future<void> updateAppointmentStatus(BookingsModel doctorNotes) async {
    if (userModelSupabase?.id != null) {
      isLoading.value = true;
      var response = await supabaseController.updateBookingStatus(doctorNotes?.id ?? 0, doctorNotes);
      isLoading.value = false;
    }
  }

  /*void loadAppointments() {
    isLoading.value = true;

    // In a real app, fetch data from your API or database
    Future.delayed(Duration(milliseconds: 800), () {
      allAppointments.value = _getMockAppointments();
      filterAppointments();
      isLoading.value = false;
    });
  }*/

  void filterAppointments() {
    final fromDateStr = DateFormat('yyyy-MM-dd').format(fromDate.value);
    final toDateStr = DateFormat('yyyy-MM-dd').format(toDate.value);

   /* filteredAppointments.value = allAppointments
        .where((appointment) {
          final appDate = appointment.date;
          return appDate.compareTo(fromDateStr) >= 0 &&
                 appDate.compareTo(toDateStr) <= 0;
        })
        .toList();*/
  }

  void applyQuickFilter(int days) {
    toDate.value = DateTime.now();
    fromDate.value = DateTime.now().subtract(Duration(days: days));
    getFilteredBookings();
  }

  void filterCurrentMonth() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    fromDate.value = firstDayOfMonth;
    toDate.value = now;
    getFilteredBookings();
  }

  /*void loadAppointmentDetails(String appointmentId) {
    isLoadingDetails.value = true;
    selectedAppointment.value = null;

    // In a real app, fetch data from your API or database
    Future.delayed(Duration(milliseconds: 800), () {
      final appointment = _getMockAppointmentDetails(appointmentId);
      selectedAppointment.value = appointment;
      isLoadingDetails.value = false;
    });
  }*/

  void cancelAppointment(BookingsModel appointment) {
    // In a real app, call your API to cancel the appointment
    Get.snackbar(
      'Appointment Cancelled',
      'Your appointment has been successfully cancelled',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void sendReminderNotification() async {
    var appointment = selectedAppointment.value;
    var doctorId = appointment?.doctorId ?? 0;
    var userId = appointment?.userId ?? 0;
    var bookingDate = appointment?.bookingDate ?? "";

    if(userModelSupabase?.userType?.toLowerCase() == UserType.patient.name) {
      await supabaseController.sentNotification(
        doctorId, "Patient: ${appointment?.aPatient().name} ",
        "The appointment on ${bookingDate}, patient has requested a callback",);
    } else {
      await supabaseController.sentNotification(
        userId, "Appointment Reminder: ${appointment?.aPatient().name} ",
        "The appointment on ${bookingDate}. Reminder has been sent by the doctor: ${appointment?.aDoctor().name}.",);
    }
  }
    /*// Update local data
    final index = allAppointments.indexWhere((a) => a.appointmentId == appointmentId);
    if (index >= 0) {
      allAppointments[index] = allAppointments[index].copyWith(status: 'cancelled');
      filterAppointments();
    }

    // Update selected appointment if viewing details
    if (selectedAppointment.value?.appointmentId == appointmentId) {
      selectedAppointment.value = selectedAppointment.value!.copyWith(status: 'cancelled');
    }*/
}