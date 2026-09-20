enum UserType { patient, doctor }
enum BookingStatus { pending, booked, completed, cancelled, noShow }
enum PaymentStatus { paid, pending, refunded, failed }
enum LoadingStatusEnum { initial, loading, success }
enum ApiTypeEnum { get, post, delete, put }
bool isNumeric(String s) => s.isNotEmpty && double.tryParse(s) != null;