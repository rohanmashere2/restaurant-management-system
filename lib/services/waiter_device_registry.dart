import 'package:cloud_firestore/cloud_firestore.dart';

/// Indexes `deviceCode` → owner + waiter for O(1) lookup on the selection screen.
/// Document ID is a sanitized [deviceCode] (Firestore path-safe).
class WaiterDeviceRegistry {
  static const collection = 'waiter_devices';

  static String docIdForDevice(String deviceCode) {
    if (deviceCode.isEmpty) return 'unknown_device';
    return deviceCode.replaceAll(RegExp(r'[/.#$\[\]]'), '_');
  }

  static Future<void> upsert({
    required String deviceCode,
    required String ownerUserId,
    required String username,
    required bool active,
  }) async {
    final id = docIdForDevice(deviceCode);
    await FirebaseFirestore.instance.collection(collection).doc(id).set({
      'ownerUserId': ownerUserId,
      'username': username,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// True if [username] exists under [ownerUserId], is not explicitly deactivated,
  /// and [deviceCode] matches the waiter record (session integrity).
  static Future<bool> waiterDeviceMatchesOwner({
    required String ownerUserId,
    required String username,
    required String deviceCode,
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUserId)
        .get();
    final data = snap.data();
    if (data == null || data['waiters'] is! List) return false;
    for (final w in data['waiters'] as List) {
      if (w is! Map) continue;
      if (w['username']?.toString() != username) continue;
      if (w['active'] == false) return false;
      final saved = w['deviceCode']?.toString() ?? '';
      return saved == deviceCode;
    }
    return false;
  }

  static Future<void> deactivateByDeviceCode(String? deviceCode) async {
    if (deviceCode == null || deviceCode.isEmpty) return;
    final id = docIdForDevice(deviceCode);
    await FirebaseFirestore.instance.collection(collection).doc(id).set({
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
