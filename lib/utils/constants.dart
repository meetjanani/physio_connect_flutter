import '../model/user_model_supabase.dart';
import 'enum.dart';

const LAT_LONG_SEPRATOR = "@-@";

/// Legacy allowlist kept only as a fallback while existing doctor rows
/// may still have blank/incorrect [userType] in Supabase.
const DOCTOR_USER_ID_LIST = [3, 8, 65];

/// Resolves doctor role from [UserModelSupabase.userType], with a legacy
/// ID allowlist fallback for older accounts.
bool isDoctorTypeUser(UserModelSupabase? user) {
  if (user == null) return false;
  final type = (user.userType ?? '').toLowerCase().trim();
  if (type == UserType.doctor.name || type == 'doctor') return true;
  if (type == UserType.patient.name || type == 'patient') return false;
  return DOCTOR_USER_ID_LIST.contains(user.id);
}

/// Patient cancel: full refund if cancelled more than this many hours ahead.
const int FREE_CANCEL_HOURS = 24;

const String SUPPORT_WHATSAPP = '919510443624';
const String SUPPORT_EMAIL = 'physioconnect.app@gmail.com';
const String APP_SHARE_MESSAGE =
    'Better movement starts with the right care. PhysioConnect connects you '
    'with trusted physiotherapists for personalized care at home. Share the '
    'journey to feeling stronger with someone you care about!\n\n'
    'Download: http://play.google.com/store/apps/details?id=com.physio.connect.physio_connect&hl=en_IN';
