import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figmaap/services/user_service.dart';

class NotificationService {
  final _firestore = FirebaseFirestore.instance;

  String? get _currentUserId => UserService.currentUserId;

  // orderBy kasıtlı olarak eklenmedi: 'userId' eşitlik filtresiyle birlikte
  // farklı bir alanda (createdAt) sıralama, Firestore'da elle oluşturulması
  // gereken bir composite index gerektirir. Bunun yerine sıralama, sonucu
  // kullanan tarafta (notifications_page.dart) istemci tarafında yapılıyor.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchNotifications() {
    final userId = _currentUserId;
    if (userId == null) return const Stream.empty();
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Stream<int> watchUnreadCount() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(0);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }

  /// "Randevunuz yaklaşıyor" hatırlatması: bugüne ait, onaylanmış (upcoming)
  /// ve daha önce hatırlatması gönderilmemiş randevular için bir bildirim
  /// oluşturur. Sunucu tarafında zamanlanmış görev (Cloud Functions, Blaze
  /// plan gerektirir) olmadığından bu kontrol istemci tarafında, uygulama
  /// her açıldığında (bkz. main_page.dart initState) çalıştırılır.
  /// 'reminderSent' bayrağı booking dokümanına yazılarak aynı gün içinde
  /// tekrar tekrar bildirim oluşturulması engellenir.
  Future<void> checkTodayReminders() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final now = DateTime.now();
    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'upcoming')
        .where('dateIso', isEqualTo: todayIso)
        .get();

    for (final doc in snapshot.docs) {
      final booking = doc.data();
      if (booking['reminderSent'] == true) continue;

      await _firestore.collection('notifications').add({
        'userId': userId,
        'bookingId': doc.id,
        'type': 'reminder',
        'title': 'Randevunuz yaklaşıyor',
        'body':
            '${booking['service'] ?? 'Randevunuz'} bugün ${booking['time'] ?? ''}',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await doc.reference.update({'reminderSent': true});
    }
  }
}
