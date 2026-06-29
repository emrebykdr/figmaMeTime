import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;

  static String? currentPhone;
  static String? currentUserName;

  Future<void> registerUser({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await _firestore.collection('users').add({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
    currentPhone = phone;
    currentUserName = fullName;
  }

  Future<bool> loginUser({required String phone}) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      currentPhone = phone;
      currentUserName = data['fullName'] as String?;
      return true;
    }
    currentPhone = phone;
    currentUserName = null;
    return false;
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }
}
