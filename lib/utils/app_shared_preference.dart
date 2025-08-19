import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model_supabase.dart';

const String userIdSessionStorage = 'userId';
const String userNameSessionStorage = 'userName';
const String doctorNameSessionStorage = 'doctorName';
const String doctorIdSessionStorage = 'doctorId';
const String userCreatedAtSessionStorage = 'userCreatedAt';
const String userMobileNumberSessionStorage = 'userMobileNumber';
const String userIsAdminSessionStorage = 'userIsAdmin';
const String userProfileFirebaseToken = 'firebaseToken';

Future<UserModelSupabase> getUserModel() async {
  var sharedPreference = await SharedPreferences.getInstance();
  var user = UserModelSupabase(
    id: sharedPreference.getInt(userIdSessionStorage) ?? 0,
    name: sharedPreference.getString(userNameSessionStorage) ?? '',
    doctorName: sharedPreference.getString(doctorNameSessionStorage) ?? '',
    doctorId: sharedPreference.getInt(doctorIdSessionStorage) ?? 0,
    mobileNumber: sharedPreference.getString(userMobileNumberSessionStorage) ?? '',
  );
  user.createAt = sharedPreference.getString(userCreatedAtSessionStorage) ?? '';
  user.firebaseToken = sharedPreference.getString(userProfileFirebaseToken) ?? '';
  return await user;
}

Future<void> setUserModel(UserModelSupabase userModelSupabase) async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setInt(userIdSessionStorage, userModelSupabase.id);
  sharedPreference.setString(userNameSessionStorage, userModelSupabase.name);
  sharedPreference.setString(doctorNameSessionStorage, userModelSupabase.doctorName);
  sharedPreference.setInt(doctorIdSessionStorage, userModelSupabase.doctorId);
  sharedPreference.setString(userCreatedAtSessionStorage, userModelSupabase.createAt);
  sharedPreference.setString(userMobileNumberSessionStorage, userModelSupabase.mobileNumber);
  sharedPreference.setString(userProfileFirebaseToken, userModelSupabase.firebaseToken);
}

Future<void> updateFirebaseToken(String firebaseToken) async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setString(userProfileFirebaseToken, firebaseToken);
}

Future<String> getColabUserName() async {
  var sharedPreference = await SharedPreferences.getInstance();
  return sharedPreference.getString('userName') ?? "";
}

Future<String> getColabKey(String key) async {
  var sharedPreference = await SharedPreferences.getInstance();
  return await sharedPreference.getString(key) ?? '';
}

Future<void> setColabKey(String key, String value) async {
  var sharedPreference = await SharedPreferences.getInstance();
  sharedPreference.setString(key, value);
}