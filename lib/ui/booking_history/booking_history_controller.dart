// lib/ui/booking/history/booking_history_controller.dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../model/appointment_model.dart';
import '../../model/bookings_model.dart';
import '../../model/user_model_supabase.dart';
import '../../supabase/supabase_controller.dart';
import '../../utils/app_shared_preference.dart';

class BookingHistoryController extends GetxController {
  static BookingHistoryController get to => Get.put(BookingHistoryController());

  final isLoading = true.obs;
  final isLoadingDetails = false.obs;

  // Date filter
  final fromDate = DateTime.now().subtract(Duration(days: 7)).obs;
  final toDate = DateTime.now().obs;

  // Appointments
  final allAppointments = <AppointmentModel>[].obs;
  final selectedAppointment = Rx<BookingsModel?>(null);

  SupabaseController supabaseController =
      SupabaseController.to;
  UserModelSupabase? userModelSupabase;
  RxList<BookingsModel> upComingBookings = RxList();
  final therapistsImage = "https://randomuser.me/api/portraits/women/44.jpg";

  @override
  Future<void> onInit() async {
    super.onInit();
    userModelSupabase = await getUserModel();
    getUpComingBookings();
  }

  Future<void> getUpComingBookings() async {
    if (userModelSupabase?.id != null) {
      isLoading.value = true;
      upComingBookings.clear();
      var response = await supabaseController.getFilteredBookings(userModelSupabase?.id ?? 0, fromDate.value, toDate.value);
      upComingBookings.addAll(response);
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
    getUpComingBookings();
  }

  void filterCurrentMonth() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    fromDate.value = firstDayOfMonth;
    toDate.value = now;
    getUpComingBookings();
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

  // Mock data - replace with real data in your app
  List<AppointmentModel> _getMockAppointments() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');

    return [
      AppointmentModel(
        appointmentId: '1',
        userId: 'user1',
        therapistId: 'therapist1',
        sessionTypeId: 'type1',
        sessionTypeName: 'General Physiotherapy',
        date: formatter.format(now.add(Duration(days: 2))),
        startTime: '10:00 AM',
        endTime: '10:45 AM',
        status: 'booked',
        paymentStatus: 'Paid',
        amount: 1200,
        therapistName: 'Dr. Sarah Johnson',
        therapistImage: 'https://randomuser.me/api/portraits/women/44.jpg',
        createdAt: now.subtract(Duration(days: 3)),
      ),
      AppointmentModel(
        appointmentId: '2',
        userId: 'user1',
        therapistId: 'therapist2',
        sessionTypeId: 'type2',
        sessionTypeName: 'Sports Rehabilitation',
        date: formatter.format(now.subtract(Duration(days: 2))),
        startTime: '2:30 PM',
        endTime: '3:30 PM',
        status: 'completed',
        paymentStatus: 'Paid',
        amount: 1800,
        therapistName: 'Dr. Michael Chen',
        therapistImage: 'https://randomuser.me/api/portraits/men/32.jpg',
        createdAt: now.subtract(Duration(days: 10)),
      ),
      AppointmentModel(
        appointmentId: '3',
        userId: 'user1',
        therapistId: 'therapist3',
        sessionTypeId: 'type3',
        sessionTypeName: 'Neurological Therapy',
        date: formatter.format(now.subtract(Duration(days: 5))),
        startTime: '9:00 AM',
        endTime: '10:00 AM',
        status: 'cancelled',
        paymentStatus: 'Refunded',
        amount: 2000,
        therapistName: 'Dr. Emily Wilson',
        therapistImage: 'https://randomuser.me/api/portraits/women/66.jpg',
        createdAt: now.subtract(Duration(days: 8)),
      ),
      AppointmentModel(
        appointmentId: '4',
        userId: 'user1',
        therapistId: 'therapist1',
        sessionTypeId: 'type1',
        sessionTypeName: 'General Physiotherapy',
        date: formatter.format(now.add(Duration(days: 5))),
        startTime: '11:30 AM',
        endTime: '12:15 PM',
        status: 'booked',
        paymentStatus: 'Paid',
        amount: 1200,
        therapistName: 'Dr. Sarah Johnson',
        therapistImage: 'https://randomuser.me/api/portraits/women/44.jpg',
        createdAt: now.subtract(Duration(days: 1)),
      ),
      AppointmentModel(
        appointmentId: '5',
        userId: 'user1',
        therapistId: 'therapist4',
        sessionTypeId: 'type4',
        sessionTypeName: 'Geriatric Physiotherapy',
        date: formatter.format(now.subtract(Duration(days: 10))),
        startTime: '4:00 PM',
        endTime: '4:45 PM',
        status: 'no-show',
        paymentStatus: 'Paid',
        amount: 1500,
        therapistName: 'Dr. Robert Taylor',
        therapistImage: 'https://randomuser.me/api/portraits/men/64.jpg',
        createdAt: now.subtract(Duration(days: 15)),
      ),
    ];
  }

  AppointmentDetails? _getMockAppointmentDetails(String appointmentId) {
    final appointment = allAppointments.firstWhereOrNull(
      (a) => a.appointmentId == appointmentId
    );

    if (appointment == null) return null;

    return AppointmentDetails(
      appointmentId: appointment.appointmentId,
      userId: appointment.userId,
      therapistId: appointment.therapistId,
      sessionTypeId: appointment.sessionTypeId,
      sessionTypeName: appointment.sessionTypeName,
      date: appointment.date,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      status: appointment.status,
      paymentStatus: appointment.paymentStatus,
      amount: appointment.amount,
      therapistName: appointment.therapistName,
      therapistImage: appointment.therapistImage,
      createdAt: appointment.createdAt,
      // Additional details
      durationMinutes: appointment.sessionTypeName.contains('General') ? 45 : 60,
      razorpayPaymentId: 'pay_${appointment.appointmentId}abcde123456',
      therapistSpecialization: _getSpecializationBySessionType(appointment.sessionTypeName),
      therapistExperience: 8,
      therapistRating: 4.8,
      doctorNotes: _getDoctorNotesByStatus(appointment.status),
    );
  }

  String _getSpecializationBySessionType(String sessionType) {
    switch (sessionType) {
      case 'Sports Rehabilitation':
        return 'Sports Medicine';
      case 'Neurological Therapy':
        return 'Neurology';
      case 'Geriatric Physiotherapy':
        return 'Geriatrics';
      case 'Pediatric Therapy':
        return 'Pediatrics';
      default:
        return 'General Practice';
    }
  }

  String _getDoctorNotesByStatus(String status) {
    if (status == 'completed') {
      return 'Patient showed good progress. Continue with the home exercises 3 times daily. Apply ice pack for 15 minutes if pain persists. Avoid high-impact activities for the next week. Follow up in 2 weeks to assess progress.';
    } else if (status == 'booked') {
      return 'Please arrive 10 minutes early to complete any paperwork. Wear comfortable clothing that allows easy movement. Bring any relevant medical records or imaging. Avoid heavy meals before the session.';
    }
    return '';
  }
}