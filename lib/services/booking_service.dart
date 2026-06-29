import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figmaap/services/user_service.dart';

class BookingService {
  final _firestore = FirebaseFirestore.instance;

  String? get _currentPhone => UserService.currentPhone;

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
      'userPhone': _currentPhone ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUpcomingBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'upcoming')
        .where('userPhone', isEqualTo: _currentPhone ?? '')
        .snapshots();
  }

  Stream<QuerySnapshot> getPastBookings() {
    return _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'past')
        .where('userPhone', isEqualTo: _currentPhone ?? '')
        .snapshots();
  }

  Future<void> cancelBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }
}
