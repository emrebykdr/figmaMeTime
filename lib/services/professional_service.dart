import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalService {
  final _firestore = FirebaseFirestore.instance;

  /// Admin panelindeki (admin_web/uzmanlar.html) 'professionals' koleksiyonundan
  /// uzman listesini çeker. Her kayıt: name, role, rating, photoUrl, salonId,
  /// workingHours (gün başına müsait saat listesi) ve daysOff (izin günleri) içerir.
  /// Sadece [salonId]'ye ait uzmanlar döner (her uzman tek bir şubeye bağlı).
  Future<List<Map<String, dynamic>>> getProfessionals({required String salonId}) async {
    final snapshot = await _firestore
        .collection('professionals')
        .where('salonId', isEqualTo: salonId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
