enum UserType { patient, therapist }
enum BookingStatus { booked, completed, cancelled, noShow }
enum PaymentStatus { paid, pending, refunded }
enum LoadingStatusEnum { initial, loading, success }
enum ApiTypeEnum { get, post, delete, put }
bool isNumeric(String s) => s.isNotEmpty && double.tryParse(s) != null;