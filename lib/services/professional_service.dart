import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalService {
  final _firestore = FirebaseFirestore.instance;

  /// Admin panelindeki (admin_web/uzmanlar.html) 'professionals' koleksiyonundan
  /// uzman listesini çeker. Her kayıt: name, role, rating, photoUrl,
  /// workingHours (gün başına müsait saat listesi) ve daysOff (izin günleri) içerir.
  Future<List<Map<String, dynamic>>> getProfessionals() async {
    final snapshot = await _firestore.collection('professionals').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
