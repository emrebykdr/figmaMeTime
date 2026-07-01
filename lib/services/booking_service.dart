import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figmaap/services/user_service.dart';

class BookingService {
  final _firestore = FirebaseFirestore.instance;

  String? get _currentUserId => UserService.currentUserId;

  /// Her randevu, kendi Firestore doküman ID'si ile eşleşen bir 'bookingId'
  /// alanıyla oluşturulur (userId'nin users koleksiyonunda tutulma şekliyle aynı desen).
  Future<String> addBooking({
    required String salon,
    required String professional,
    required String service,
    required String date,
    required String time,
    required String price,
  }) async {
    //bookingid kaydediliyor .
    final docRef = _firestore.collection('bookings').doc();
    await docRef.set({
      'bookingId': docRef.id,
      'salon': salon,
      'professional': professional,
      'service': service,
      'date': date,
      'time': time,
      'price': price,
      'status': 'waiting',
      'userId': _currentUserId ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<QuerySnapshot> getWaitingBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'waiting')
        .where('userId', isEqualTo: _currentUserId ?? '')
        .snapshots();
  }

  Stream<QuerySnapshot> getUpcomingBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'upcoming')
        .where('userId', isEqualTo: _currentUserId ?? '')
        .snapshots();
  }

  Stream<QuerySnapshot> getPastBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'past')
        .where('userId', isEqualTo: _currentUserId ?? '')
        .snapshots();
  }

  /// Admin panelinden randevu onaylandığında çağrılır: 'waiting' -> 'upcoming'.
  Future<void> approveBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'upcoming',
    });
  }

  /// Belirli bir uzman ve tarih için zaten onaylanmış (upcoming) saatleri döner.
  /// Randevu alma ekranında bu saatler seçilemez hale getirilir.
  Future<Set<String>> getBookedTimes({
    required String professional,
    required String date,
  }) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'upcoming')
        .where('professional', isEqualTo: professional)
        .where('date', isEqualTo: date)
        .get();
    return snapshot.docs.map((doc) => doc.data()['time'] as String).toSet();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }
}
