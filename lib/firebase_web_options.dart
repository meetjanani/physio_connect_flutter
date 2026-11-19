import 'package:firebase_core/firebase_core.dart';

/// Firebase config for the **web** build only ("PhysioConnect Web" app in
/// Firebase project physio-connect-app).
///
/// Android and iOS keep using google-services.json / GoogleService-Info.plist.
/// These values are public client identifiers (not secrets); access is
/// protected by Firebase security rules and App Check.
const FirebaseOptions firebaseWebOptions = FirebaseOptions(
  apiKey: 'AIzaSyC54kHx3dq918OZF-6kM6ttv9VNSvS7Oms',
  appId: '1:606815716910:web:66457d0124c377312701bf',
  messagingSenderId: '606815716910',
  projectId: 'physio-connect-app',
  authDomain: 'physio-connect-app.firebaseapp.com',
  storageBucket: 'physio-connect-app.firebasestorage.app',
  measurementId: 'G-S1EG4MCT4J',
);
