// lib/utils/secure_storage_repository.dart
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class SecureStorageRepository implements SecureStorageProvider {
  static SecureStorageRepository get to => Get.find();

  // Common keys
  static const token = "secure_token";
  static const refreshToken = "refresh_token";
  static const userId = "user_id";
  static const biometricEnabled = "biometric_enabled";

  final FlutterSecureStorage _secureStorage;

  // Configure with iOS options if needed
  SecureStorageRepository([FlutterSecureStorage? secureStorage])
    : _secureStorage = secureStorage ?? FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

  @override
  Future<String?> read(String key) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<bool> containsKey(String key) async {
    return await _secureStorage.containsKey(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<Map<String, String>> readAll() async {
    return await _secureStorage.readAll();
  }

  // Helper methods for common use cases
  Future<void> saveToken(String value) async {
    await write(token, value);
  }

  Future<String?> getToken() async {
    return await read(token);
  }

  Future<bool> hasToken() async {
    return await containsKey(token);
  }

  // Helper to encode and store complex objects (as JSON)
  Future<void> writeObject(String key, Map<String, dynamic> value) async {
    final String jsonString = jsonEncode(value);
    await write(key, jsonString);
  }

  // Helper to decode stored JSON objects
  Future<Map<String, dynamic>?> readObject(String key) async {
    final String? jsonString = await read(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}


// lib/utils/secure_storage_provider.dart
abstract class SecureStorageProvider {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<bool> containsKey(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();
}