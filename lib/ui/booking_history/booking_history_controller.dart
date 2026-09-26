// lib/ui/booking/history/booking_history_controller.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:physio_connect/utils/view_extension.dart';

import '../../model/bookings_model.dart';
import '../../model/refund_response_model.dart';
import '../../model/user_model_supabase.dart';
import '../../supabase/supabase_controller.dart';
import '../../utils/constants.dart';
import '../../utils/theme/app_colors.dart';

class BookingHistoryController extends GetxController {
  static BookingHistoryController get to => Get.put(BookingHistoryController());

  final isLoading = true.obs;

  // Date filter
  final fromDate = DateTime.now().subtract(Duration(days: 7)).obs;
  final toDate = DateTime.now().add(Duration(days: 7)).obs;

  // Appointments
  final selectedAppointment = Rx<BookingsModel?>(null);

  SupabaseController supabaseController = SupabaseController.to;
  UserModelSupabase? userModelSupabase;
  RxList<BookingsModel> upComingBookings = RxList();
  RxBool isDoctor = false.obs;
  final therapistsImage = "https://randomuser.me/api/portraits/women/44.jpg";

  @override
  Future<void> onInit() async {
    super.onInit();
    userModelSupabase = await UserModelSupabase.getFromSecureStorage();
    isDoctor.value = isDoctorTypeUser(userModelSupabase?.id ?? 0);
    getFilteredBookings();
  }

  Future<void> getFilteredBookings() async {
    if (userModelSupabase?.id != null) {
      isLoading.value = true;
      upComingBookings.clear();
      var response = await supabaseController.getFilteredBookings(
        userModelSupabase?.id ?? 0,
        fromDate.value,
        toDate.value,
        isDoctor.value,
      );
      upComingBookings.addAll(response);
      isLoading.value = false;
      showSuccessSnackbar("${upComingBookings.value.length}");
    }
  }

  Future<void> updateDoctorNote(BookingsModel bookingModel) async {
    if (userModelSupabase?.id != null) {
      isLoading.value = true;
      var response = await supabaseController.updateDoctorNote(
        bookingModel?.id ?? 0,
        bookingModel,
      );
      isLoading.value = false;
    }
  }

  Future<void> updateAppointmentStatus(BookingsModel bookingModel) async {
    if (userModelSupabase?.id != null) {
      isLoading.value = true;
      try {
        final isRefunded =
            bookingModel.razorpayRefundId?.trim().isNotEmpty == true ||
            bookingModel.paymentStatus.toLowerCase() == 'refunded' ||
            bookingModel.bookingStatus.toLowerCase() == 'refunded';
        if (isRefunded) {
          bookingModel.bookingStatus = 'refunded';
        }
        await supabaseController.updateBookingStatus(
          bookingModel.id,
          bookingModel,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> rescheduleAppointment(
    BookingsModel appointment,
    DateTime newDate,
  ) async {
    isLoading.value = true;
    try {
      final bookingDate = DateFormat('yyyy-MM-dd').format(newDate);
      await supabaseController.updateBookingDate(appointment.id, bookingDate);
      appointment.bookingDate = bookingDate;
      selectedAppointment.value = appointment;

      final index = upComingBookings.indexWhere((booking) {
        return booking.id == appointment.id;
      });
      if (index != -1) {
        upComingBookings[index] = appointment;
      }

      Get.snackbar(
        'Appointment Rescheduled',
        'The appointment was moved to $bookingDate.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
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

  void sendReminderNotification() async {
    var appointment = selectedAppointment.value;
    var doctorId = appointment?.doctorId ?? 0;
    var userId = appointment?.userId ?? 0;
    var bookingDate = appointment?.bookingDate ?? "";

    if (isDoctorTypeUser(userModelSupabase?.id ?? 0) == false) {
      // patient type user
      await supabaseController.sentNotification(
        doctorId,
        "Patient: ${appointment?.aPatient().name} ",
        "The appointment on ${bookingDate}, patient has requested a callback",
      );
    } else {
      await supabaseController.sentNotification(
        userId,
        "Appointment Reminder: ${appointment?.aPatient().name} ",
        "The appointment on ${bookingDate}. Reminder has been sent by the doctor: ${appointment?.aDoctor().name}.",
      );
    }
  }

  Future<RefundResponseModel> processRefundForPatient(
    String bookingId,
    String doctorId,
  ) async {
    // 1. Show Loading State
    isLoading.value = true;

    // (Optional: Show a loading dialog here if you prefer that over a spinner)

    // 2. Call the function
    final result = await supabaseController.callInitiateRefundEdgeFunction(
      bookingId: bookingId,
      doctorId: doctorId,
    );
    selectedAppointment.value = await supabaseController.getBookingById(bookingId);


    // 3. Hide Loading State
    isLoading.value = false;

    // 4. Handle UI based on the smart model
    if (result.success) {
      // Show success using your existing view extensions / GetX snackbars
      Get.snackbar(
        'Refund Successful',
        result.message ?? 'The money has been routed back to the patient.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.9),
        colorText: AppColors.textOnDark,
      );

      print('Refund ID saved: ${result.refundId}');

      // TODO: Update your local list of bookings to reflect "refunded" status
    } else {
      // Show the beautifully parsed error message directly to the doctor
      Get.snackbar(
        'Refund Failed',
        result.errorMessage ?? 'Something went wrong. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.9),
        colorText: AppColors.textOnDark,
        duration: const Duration(
          seconds: 4,
        ), // Give them time to read longer errors
      );
    }

    return result;
  }
}
