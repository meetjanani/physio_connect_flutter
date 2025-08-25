
import 'package:intl/intl.dart';

// Convert "2025-08-26" to "20 Oct 2023"
String formatDateToReadable(String dateStr) {
  final DateTime date = DateTime.parse(dateStr);
  final DateFormat formatter = DateFormat('d MMM yyyy');
  return formatter.format(date);
}

// Convert "2025-08-26" to "Friday"
String formatDateToWeekday(String dateStr) {
  final DateTime date = DateTime.parse(dateStr);
  final DateFormat formatter = DateFormat('EEEE');
  return formatter.format(date);
}