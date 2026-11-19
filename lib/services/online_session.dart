import 'package:url_launcher/url_launcher.dart';

import '../model/bookings_model.dart';

class OnlineSession {
  OnlineSession._();

  static bool isPaidOnline(BookingsModel booking) {
    if (!booking.isOnlineSession) return false;
    final payment = booking.paymentStatus.toLowerCase();
    final status = booking.bookingStatus.toLowerCase();
    if (payment != 'paid') return false;
    if (status == 'cancelled' ||
        status == 'canceled' ||
        status == 'refunded') {
      return false;
    }
    return true;
  }

  static String? meetingUrl(BookingsModel booking) {
    final url = booking.meetingUrl?.trim() ?? '';
    if (url.isEmpty) return null;
    return url;
  }

  static DateTime sessionStart(BookingsModel booking) {
    final date = DateTime.tryParse(booking.bookingDate) ?? DateTime.now();
    var slotTime = '09:00';
    try {
      slotTime = booking.aTimeslot().time;
    } catch (_) {}
    return combineDateAndSlot(date, slotTime);
  }

  static DateTime combineDateAndSlot(DateTime date, String slotTime) {
    final cleaned = slotTime.trim().toUpperCase();
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?').firstMatch(cleaned);
    var hour = 9;
    var minute = 0;
    if (match != null) {
      hour = int.tryParse(match.group(1) ?? '9') ?? 9;
      minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final ampm = match.group(3);
      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static int durationMinutes(BookingsModel booking) {
    var raw = '45';
    try {
      raw = booking.aSessionType().duration;
    } catch (_) {}
    final match = RegExp(r'(\d+)').firstMatch(raw);
    return int.tryParse(match?.group(1) ?? '45') ?? 45;
  }

  static bool isJoinWindow(BookingsModel booking) {
    if (!isPaidOnline(booking)) return false;
    final start = sessionStart(booking);
    final end = start.add(Duration(minutes: durationMinutes(booking)));
    final now = DateTime.now();
    return !now.isBefore(start.subtract(const Duration(minutes: 15))) &&
        !now.isAfter(end);
  }

  static Future<bool> launchMeeting(String url) async {
    var uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String? whatsappDigits(String? raw) {
    var digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length == 10) digits = '91$digits';
    return digits;
  }

  static Future<bool> launchWhatsApp(String? phone, {String? message}) async {
    final digits = whatsappDigits(phone);
    if (digits == null) return false;
    final params = <String, String>{};
    if (message != null && message.trim().isNotEmpty) {
      params['text'] = message.trim();
    }
    final uri = Uri.https('wa.me', '/$digits', params);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
