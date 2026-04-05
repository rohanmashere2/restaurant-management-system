import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registers the device for Firebase Cloud Messaging and stores the token on
/// the manager's `users/{uid}` document for server-side or console pushes.
class FcmService {
  static Future<void> registerManagerDevice(String uid) async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await messaging.getToken();
    if (token == null) return;

    await _saveToken(uid, token);

    messaging.onTokenRefresh.listen((t) {
      _saveToken(uid, t);
    });
  }

  static Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
