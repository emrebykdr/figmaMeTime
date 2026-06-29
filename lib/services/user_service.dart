import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await _saveSession(phone, fullName);
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
      await _saveSession(phone, currentUserName ?? '');
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

  Future<void> _saveSession(String phone, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_name', name);
    await prefs.setBool('is_logged_in', true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    currentPhone = prefs.getString('user_phone');
    currentUserName = prefs.getString('user_name');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    currentPhone = null;
    currentUserName = null;
  }
}
