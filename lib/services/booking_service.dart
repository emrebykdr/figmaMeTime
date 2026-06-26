// lib/services/booking_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BookingService {
  final _firestore = FirebaseFirestore.instance;

  // Randevu ekle
  Future<void> addBooking({
    required String salon,
    required String professional,
    required String service,
    required String date,
    required String time,
    required String price,
  }) async {
    await _firestore.collection('bookings').add({
      'salon': salon,
      'professional': professional,
      'service': service,
      'date': date,
      'time': time,
      'price': price,
      'status': 'upcoming',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Upcoming randevuları getir
  Stream<QuerySnapshot> getUpcomingBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'upcoming')
        .snapshots();
  }

  // Past randevuları getir
  Stream<QuerySnapshot> getPastBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'past')
        .snapshots();
  }

  // Randevu iptal et
  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }
}
