import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/bookings_model.dart';
import '../../model/user_model_supabase.dart';
import '../../route/route_module.dart';
import '../../supabase/supabase_controller.dart';
import '../../utils/common_appbar.dart';
import 'booking_detail_screen.dart';

/// Entry point for `/booking-detail?id=<bookingId>`.
///
/// In-app navigation passes the booking as an argument and it is shown right
/// away. On the website the page can also be opened from the URL alone
/// (refresh, bookmark, shared link): the booking is then loaded by id, and
/// only shown to its patient or doctor.
class BookingDetailRoute extends StatefulWidget {
  const BookingDetailRoute({super.key});

  @override
  State<BookingDetailRoute> createState() => _BookingDetailRouteState();
}

class _BookingDetailRouteState extends State<BookingDetailRoute> {
  BookingsModel? _booking;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is BookingsModel) {
      _booking = args;
    } else {
      _load(Get.parameters['id']);
    }
  }

  Future<void> _load(String? id) async {
    try {
      final bookingId = int.tryParse(id ?? '');
      if (bookingId == null) throw StateError('missing id');
      final results = await Future.wait([
        SupabaseController.to.getBookingById(bookingId.toString()),
        UserModelSupabase.getFromSecureStorage(),
      ]);
      final booking = results[0] as BookingsModel?;
      final me = results[1] as UserModelSupabase?;
      final myId = me?.id ?? 0;
      final allowed = booking != null &&
          myId > 0 &&
          (booking.userId == myId || booking.doctorId == myId);
      if (!mounted) return;
      setState(() {
        _booking = allowed ? booking : null;
        _failed = !allowed;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    if (booking != null) return BookingDetailScreen(initialAppointment: booking);
    return Scaffold(
      appBar: commonAppBar('Appointment', isBackButtonVisible: true),
      body: Center(
        child: _failed
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This appointment could not be found.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          Get.offAllNamed(AppPage.dashboardScreen),
                      child: const Text('Go to dashboard'),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
