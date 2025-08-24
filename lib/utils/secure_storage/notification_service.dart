import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {

  static String? notificationAccessToken;

  Future<String> getAccessToken() async {
    // Load your service account JSON (put in assets for testing ONLY)
    final serviceAccountJson = await rootBundle.loadString('assets/service_account.json');
    final credentials = auth.ServiceAccountCredentials.fromJson(serviceAccountJson);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await auth.clientViaServiceAccount(credentials, scopes);
    final accessToken = client.credentials.accessToken.data;
    client.close();

    notificationAccessToken = accessToken;
    return accessToken;
  }


  Future<void> sendPushNotification(String deviceToken,  String title, String messageBody) async {
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
        /*"data": {
          "screen": "booking",
          "doctorId": "1234"
        }*/
      }
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $notificationAccessToken",
      },
      body: jsonEncode(body),
    );

    print("Response: ${response.statusCode} ${response.body}");
  }
}
