import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

class NotificationService {

  static String? notificationAccessToken;
  DateTime? _tokenExpiry;

  Future<String> getAccessToken() async {
    // Check if cached token is still valid
    if (notificationAccessToken != null && _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now().add(Duration(minutes: 5)))) {
      return notificationAccessToken!;
    }

    try {
      // Call Firebase Function to get token
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('getFcmToken').call();

      final data = result.data;
      notificationAccessToken = data['token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expiryTime']));

      return notificationAccessToken!;
    } catch (e) {
      print('Error getting access token: $e');
      throw Exception('Failed to get FCM token: $e');
    }
  }


  Future<void> sendPushNotification(String deviceToken,  String title, String messageBody) async {
    try {
      notificationAccessToken ??= await getAccessToken();

      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/physio-connect-app/messages:send');

      final body = {
        "message": {
          "token": deviceToken,
          "notification": {
            "title": title,
            "body": messageBody
          },
          "data": {
            "screen": "booking",
            "doctorId": "1234"
          }
        }
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${notificationAccessToken}",
        },
        body: jsonEncode(body),
      );

      print("Response: ${response.statusCode} ${response.body}");
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }
}
