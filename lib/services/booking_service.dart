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
    required DateTime appointmentDate,
  }) async {
    // Admin panelinden "Randevuları Kısıtla" ile işaretlenmiş hesaplar
    // (users/{id}.bookingRestricted == true) yeni randevu oluşturamaz.
    if (_currentUserId != null) {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      if (userDoc.data()?['bookingRestricted'] == true) {
        throw Exception('Hesabınız randevu almaya kapatılmıştır. Lütfen salon ile iletişime geçin.');
      }
    }

    //bookingid kaydediliyor .
    final docRef = _firestore.collection('bookings').doc();
    await docRef.set({
      'bookingId': docRef.id,
      'salon': salon,
      'professional': professional,
      'service': service,
      'date': date,
      // Randevunun gerçekleşeceği tarih, yıl/ay dahil sıralanabilir formatta
      // (ör. '2026-07-15'). 'date' alanı sadece görünüm metni (ay/yıl yok),
      // admin panelindeki sıralama/takvim/filtreleme bu alana göre çalışır.
      'dateIso': _isoDate(appointmentDate),
      'time': time,
      'price': price,
      'status': 'waiting',
      'userId': _currentUserId ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  /// Belirli bir uzman ve tarih için dolu sayılan saatleri döner: hem onay
  /// bekleyen (waiting) hem de onaylanmış (upcoming) randevular dahildir.
  /// Böylece aynı uzman/saat için birden fazla waiting kaydı oluşup admin
  /// tarafında çakışma yaratılması, kaynağında (booking ekranında) engellenir.
  /// Randevu alma ekranında bu saatler seçilemez hale getirilir.
  Future<Set<String>> getBookedTimes({
    required String professional,
    required String date,
  }) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('status', whereIn: ['waiting', 'upcoming'])
        .where('professional', isEqualTo: professional)
        .where('date', isEqualTo: date)
        .get();
    return snapshot.docs.map((doc) => doc.data()['time'] as String).toSet();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }
}
