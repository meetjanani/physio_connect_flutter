// lib/ui/booking/booking_controller.dart
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../model/session_type_model.dart';
import '../../supabase/supabase_controller.dart';

class BookingController extends GetxController {
  static BookingController get to => Get.find();
  BookingController();
  SupabaseController supabaseController =
      SupabaseController.to;

  final isLoading = false.obs;
  final isLoadingTimeSlots = false.obs;

  // Selected values through the booking flow
  final selectedSessionType = Rx<SessionTypeModel?>(null);
  final selectedDate = DateTime.now().obs;
  final selectedTimeSlot = ''.obs;
  final razorpayPaymentId = ''.obs;

  // Time slots data
  final availableTimeSlots = <String>[].obs;
  final bookedTimeSlots = <String>[].obs;

  // Mock session types for demo
  final sessionTypes = <SessionTypeModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSessionTypes();
    loadAvailableTimeSlots();
  }

  void loadSessionTypes() async {
    isLoading.value = true;
    sessionTypes.clear();
    var response = await supabaseController.getSessionTypeMaster();
    sessionTypes.addAll(response);
    isLoading.value = false;
    // Mock data - in real app, fetch from your database
    /*Future.delayed(Duration(milliseconds: 800), () {
      sessionTypes.value = [
        SessionTypeModel(
          id: '3',
          name: 'Neurological Therapy',
          description: 'Therapy focused on neurological conditions like stroke recovery or MS',
          durationMinutes: 60,
          price: 2000,
          imageUrl: 'https://images.unsplash.com/photo-1559599101-f09722fb4948',
        ),
        SessionTypeModel(
          id: '4',
          name: 'Geriatric Physiotherapy',
          description: 'Gentle therapy designed for elderly patients with age-related conditions',
          durationMinutes: 45,
          price: 1500,
          imageUrl: 'https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b',
        ),
        SessionTypeModel(
          id: '5',
          name: 'Pediatric Therapy',
          description: 'Specialized therapy for children with developmental or physical challenges',
          durationMinutes: 45,
          price: 1400,
          imageUrl: 'https://images.unsplash.com/photo-1581338834647-b0fb40704e21',
        ),
        SessionTypeModel(
          id: '6',
          name: 'Fitness and Wellness',
          description: 'Specialized therapy for children with developmental or physical challenges',
          durationMinutes: 45,
          price: 1400,
          imageUrl: 'https://images.unsplash.com/photo-1581338834647-b0fb40704e21',
        ),
      ];
      isLoading.value = false;
    });*/
  }

  void loadAvailableTimeSlots() {
    isLoadingTimeSlots.value = true;

    // Clear previous slots
    availableTimeSlots.clear();
    bookedTimeSlots.clear();
    selectedTimeSlot.value = '';

    // Mock data - in real app, fetch available slots from your database
    Future.delayed(Duration(milliseconds: 800), () {
      // Generate time slots from 9 AM to 5 PM
      final List<String> slots = [];
      final startHour = 9;
      final endHour = 17;

      for (int hour = startHour; hour < endHour; hour++) {
        slots.add('${hour.toString().padLeft(2, '0')}:00');
        slots.add('${hour.toString().padLeft(2, '0')}:30');
      }

      availableTimeSlots.value = slots;

      // Mark some random slots as booked (for demo purposes)
      final bookedCount = 3; // Number of slots to mark as booked
      final random = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < bookedCount; i++) {
        final index = (random + i * 7919) % slots.length; // Using prime number for pseudo-randomness
        bookedTimeSlots.add(slots[index]);
      }

      isLoadingTimeSlots.value = false;
    });
  }

  void createAppointment() {
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

  String calculateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final startDateTime = DateTime(2023, 1, 1, hour, minute);
    final endDateTime = startDateTime.add(Duration(minutes: durationMinutes));

    return '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
  }
}