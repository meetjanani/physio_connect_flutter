import '../model/user_model_supabase.dart';
import 'secure_storage/secure_storage_repository.dart';

class SecureStorage {
  SecureStorage._();

  static const String userIdSessionStorage = 'userId';
  static const String userNameSessionStorage = 'userName';
  static const String doctorNameSessionStorage = 'doctorName';
  static const String userTypeSessionStorage = 'userType';
  static const String doctorIdSessionStorage = 'doctorId';
  static const String userCreatedAtSessionStorage = 'userCreatedAt';
  static const String userMobileNumberSessionStorage = 'userMobileNumber';
  static const String userIsAdminSessionStorage = 'userIsAdmin';
  static const String userProfileFirebaseToken = 'firebaseToken';


  static const String doctorJson = 'doctorJson';
  static const String patientJson = 'patientJson';
  static const String timeslotJson = 'timeslotJson';

}

final secureStorageRepository = SecureStorageRepository.to;

Future<UserModelSupabase> getUserModel() async {
  var idStr = await secureStorageRepository.read(SecureStorage.userIdSessionStorage);
  var doctorIdStr = await secureStorageRepository.read(SecureStorage.doctorIdSessionStorage);
  var user = UserModelSupabase(
    id: int.tryParse(idStr ?? '') ?? 0,
    name: await secureStorageRepository.read(SecureStorage.userNameSessionStorage) ?? '',
    doctorName: await secureStorageRepository.read(SecureStorage.doctorNameSessionStorage) ?? '',
    doctorId: int.tryParse(doctorIdStr ?? '') ?? 0,
    mobileNumber: await secureStorageRepository.read(SecureStorage.userMobileNumberSessionStorage) ?? '',
  );
  user.createAt = await secureStorageRepository.read(SecureStorage.userCreatedAtSessionStorage) ?? '';
  user.firebaseToken = await secureStorageRepository.read(SecureStorage.userProfileFirebaseToken) ?? '';
  return user;
}

Future<void> setUserModel(UserModelSupabase userModelSupabase) async {
  await secureStorageRepository.write(SecureStorage.userIdSessionStorage, userModelSupabase.id.toString());
  await secureStorageRepository.write(SecureStorage.userNameSessionStorage, userModelSupabase.name);
  await secureStorageRepository.write(SecureStorage.userTypeSessionStorage, userModelSupabase.userType);
  await secureStorageRepository.write(SecureStorage.doctorNameSessionStorage, userModelSupabase.doctorName);
  await secureStorageRepository.write(SecureStorage.doctorIdSessionStorage, userModelSupabase.doctorId.toString());
  await secureStorageRepository.write(SecureStorage.userCreatedAtSessionStorage, userModelSupabase.createAt);
  await secureStorageRepository.write(SecureStorage.userMobileNumberSessionStorage, userModelSupabase.mobileNumber);
  await secureStorageRepository.write(SecureStorage.userProfileFirebaseToken, userModelSupabase.firebaseToken ?? "");
}

Future<void> updateFirebaseToken(String firebaseToken) async {
  await secureStorageRepository.write(SecureStorage.userProfileFirebaseToken, firebaseToken);
}

Future<String> getColabUserName() async {
  return await secureStorageRepository.read('userName') ?? "";
}

Future<String> getColabKey(String key) async {
  return await secureStorageRepository.read(key) ?? '';
}

Future<void> setColabKey(String key, String value) async {
  await secureStorageRepository.write(key, value);
}