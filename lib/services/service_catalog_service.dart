import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCatalogService {
  final _firestore = FirebaseFirestore.instance;

  /// Admin panelindeki (admin_web/hizmetler.html) 'services' koleksiyonundan
  /// hizmetleri çeker. Sadece [salonId]'ye ait hizmetler döner (her hizmet tek
  /// bir şubeye bağlı). category verilirse sadece o kategoriye ait hizmetler döner.
  Future<List<Map<String, dynamic>>> getServices({
    required String salonId,
    String? category,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('services')
        .where('salonId', isEqualTo: salonId);
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
