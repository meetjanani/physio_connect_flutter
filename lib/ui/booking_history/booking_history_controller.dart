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
  final therapistsImage = "https://firebasestorage.googleapis.com/v0/b/physio-connect-app.firebasestorage.app/o/Doctor_Profile_Photos%2Fpatient_common_profile_picture.jpg?alt=media&token=0c67dc67-9f2b-401a-86f3-91ff07f5c3d9";

  @override
  Future<void> onInit() async {
    super.onInit();
    userModelSupabase = await UserModelSupabase.getFromSecureStorage();
    isDoctor.value = isDoctorTypeUser(userModelSupabase);
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
        final doctor = bookingModel.aDoctor();
        final patient = bookingModel.aPatient();
        final sessionType = bookingModel.aSessionType();
        final timeSlot = bookingModel.aTimeslot();
        final parsedDate = DateTime.tryParse(bookingModel.bookingDate);
        final appointmentDate = parsedDate == null
            ? bookingModel.bookingDate
            : DateFormat('MMM d, yyyy').format(parsedDate);
        final appointmentDetails =
            '${sessionType.name} session on $appointmentDate at ${timeSlot.time}';
        final notification = _bookingStatusNotification(
          bookingModel.bookingStatus,
          patient.name ?? 'The patient',
          doctor.name ?? 'your doctor',
          appointmentDetails,
        );
        final doctorUserId = doctor.userId ?? 0;
        final patientUserId = bookingModel.userId;

        if (patientUserId > 0) {
          await supabaseController.sentNotification(
            patientUserId,
            notification.$1,
            notification.$2,
          );
        }
        if (doctorUserId > 0) {
          await supabaseController.sentNotification(
            doctorUserId,
            notification.$1,
            notification.$3,
          );
        }
      } finally {
        isLoading.value = false;
      }
    }
  }

  (String, String, String) _bookingStatusNotification(
    String bookingStatus,
    String patientName,
    String doctorName,
    String appointmentDetails,
  ) {
    final status = bookingStatus.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');
    final title = switch (status) {
      'pending' => 'Booking awaiting confirmation',
      'confirmed' => 'Booking confirmed',
      'completed' => 'Session completed',
      'cancelled' || 'canceled' => 'Booking cancelled',
      'noshow' => 'Missed appointment',
      'refunded' => 'Refund processed',
      _ => 'Booking updated',
    };
    final patientMessage = switch (status) {
      'pending' =>
        'Your $appointmentDetails with $doctorName is awaiting confirmation.',
      'confirmed' =>
        'Your $appointmentDetails with $doctorName is confirmed.',
      'completed' =>
        'Your $appointmentDetails with $doctorName has been completed.',
      'cancelled' || 'canceled' =>
        'Your $appointmentDetails with $doctorName has been cancelled.',
      'noshow' =>
        'Your $appointmentDetails with $doctorName has been marked as a no-show.',
      'refunded' =>
        'The refund for your $appointmentDetails with $doctorName has been processed.',
      _ =>
        'The status of your $appointmentDetails with $doctorName has been updated to $bookingStatus.',
    };
    final doctorMessage = switch (status) {
      'pending' =>
        '$patientName has a $appointmentDetails booking awaiting confirmation.',
      'confirmed' =>
        '$patientName has a confirmed $appointmentDetails booking.',
      'completed' =>
        '$patientName\'s $appointmentDetails has been completed.',
      'cancelled' || 'canceled' =>
        '$patientName\'s $appointmentDetails booking has been cancelled.',
      'noshow' =>
        '$patientName did not attend their $appointmentDetails.',
      'refunded' =>
        'The refund for $patientName\'s $appointmentDetails booking has been processed.',
      _ =>
        '$patientName\'s $appointmentDetails booking status was updated to $bookingStatus.',
    };
    return (title, patientMessage, doctorMessage);
  }

  Future<void> submitRating(
    BookingsModel appointment,
    int rating,
    String comment,
  ) async {
    isLoading.value = true;
    try {
      await supabaseController.submitBookingRating(
        appointment.id,
        rating: rating,
        comment: comment,
      );
      appointment.rating = rating;
      appointment.ratingComment = comment;
      Get.snackbar('Thank you', 'Your rating was saved.');
    } catch (e) {
      Get.snackbar(
        'Rating unavailable',
        'Could not save rating yet. Please try again later.',
      );
    } finally {
      isLoading.value = false;
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

      showSuccessSnackbar('Appointment Rescheduled' + "\n" +
        'The appointment was moved to $bookingDate.',);
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
    final doctor = appointment?.aDoctor();
    final patient = appointment?.aPatient();
    final timeSlot = appointment?.aTimeslot();
    final parsedDate = DateTime.tryParse(appointment!.bookingDate);
    final appointmentDate = parsedDate == null
        ? appointment.bookingDate
        : DateFormat('MMM d, yyyy').format(parsedDate);

    if (isDoctorTypeUser(userModelSupabase) == false) {
      await supabaseController.sentNotification(
        doctorId,
        '${patient?.name ?? 'A patient'} has requested a callback about their '
            'appointment scheduled for $appointmentDate at '
            '${timeSlot?.time ?? 'the scheduled time'}.',
        'Patient callback request',
      );
    } else {
      await supabaseController.sentNotification(
        userId,
        'Your appointment with ${doctor?.name ?? 'your doctor'} is scheduled '
            'for $appointmentDate at '
            '${timeSlot?.time ?? 'the scheduled time'}. This is a reminder from '
            'your doctor.',
        'Appointment reminder',
      );
    }
    final recipient = isDoctorTypeUser(userModelSupabase) ? 'patient' : 'doctor';
    Get.showSuccessSnackbar(
      'Your notification has been sent to the $recipient.',
    );
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
