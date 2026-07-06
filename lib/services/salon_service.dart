import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalonService {
  final _firestore = FirebaseFirestore.instance;

  // Kullanıcının şu anki şubesi: UserService.currentUserId ile aynı desende
  // (oturum boyunca sabit static alan) tutuluyor. Misafir akışında
  // branch_picker_page.dart, giriş yapmış kullanıcıda ise
  // account_settings_page.dart bu değeri günceller.
  static String? currentSalonId;
  static String? currentSalonName;

  Future<List<Map<String, dynamic>>> getSalons() async {
    final snapshot = await _firestore.collection('salons').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>?> getSalonById(String salonId) async {
    final doc = await _firestore.collection('salons').doc(salonId).get();
    return doc.data();
  }

  static Future<void> selectSalon(String salonId, String name) async {
    currentSalonId = salonId;
    currentSalonName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('salon_id', salonId);
    await prefs.setString('salon_name', name);
  }

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    currentSalonId = prefs.getString('salon_id');
    currentSalonName = prefs.getString('salon_name');
  }
}
