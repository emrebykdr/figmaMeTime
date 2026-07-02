import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  //login/sign up sırasında set edilen static değişken. Yani "şu an uygulamayı kim kullanıyor" bilgisi buradan okunuyor.
  // currentUserId hiç değişmez, tel  efon/isim değişse bile booking'ler bu ID ile bağlı kalır.

  static String? currentUserId;
  static String? currentPhone;
  static String? currentUserName;

  /// Telefon numarası zaten kayıtlıysa true döner.
  Future<bool> phoneExists(String phone) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  //sign up sayfası için
  /// Numara zaten kayıtlıysa kayıt oluşturmaz, false döner.
  Future<bool> registerUser({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    if (await phoneExists(phone)) {
      return false;
    }
    final docRef = _firestore.collection('users').doc();
    await docRef.set({
      'id': docRef.id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
    currentUserId = docRef.id;
    currentPhone = phone;
    currentUserName = fullName;
    await _saveSession(docRef.id, phone, fullName);
    return true;
  }

  // kullanıcı kayıtlı değilse bile telefon numarası currentPhone'a atanıyor (booking'leri ilişkilendirmek için).
  Future<bool> loginUser({required String phone}) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();
      currentUserId = doc.id;
      currentPhone = phone;
      currentUserName = data['fullName'] as String?;
      await _saveSession(doc.id, phone, currentUserName ?? '');
      return true;
    }
    currentUserId = null;
    currentPhone = phone;
    currentUserName = null;
    return false;
  }
  //Tek seferlik sorgu
  //Telefon numarası ile Firestore'da ara
  //Bulunan kullanıcının TÜM verisini (Map) döndür

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

  /// login_phone.dart artık telefon yerine email ile giriş yaptırıyor
  /// (giriş kodu Gmail üzerinden gönderildiği için). Hesabın alttaki
  /// kimliği hâlâ telefon numarası olduğundan, bulunan kullanıcının
  /// 'phone' alanı LoginPhoneCode'a aktarılmaya devam ediyor.
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  /// getUserByPhone'un canlı (stream) hali: admin panelinden kullanıcı
  /// verisi (ör. loginCode) değiştiğinde, ekran yeniden açılmadan anında
  /// günceli yayınlar. login_phone_code.dart'ta kod ekranı açıkken admin
  /// yeni kod üretirse diye kullanılıyor.
  Stream<Map<String, dynamic>?> watchUserByPhone(String phone) {
    return _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null);
  }

  /// Oturum açıkken (uygulama önden çalışırken) admin, kullanıcının hesabını
  /// engellerse bunu anında yakalamak için kullanılıyor. main.dart'taki
  /// açılış kontrolü sadece uygulama yeniden başladığında çalışıyordu; bu
  /// stream, uygulama açık kaldığı sürece de canlı dinleme sağlıyor.
  Stream<bool> watchAccountBlocked() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['accountBlocked'] == true);
  }

  /// userId sabit olduğu için telefon değişse bile doğru kullanıcıyı bulur.
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  /// Kullanıcının telefon numarasını günceller. currentUserId değişmediği
  /// için geçmiş randevular kullanıcıyla bağlı kalmaya devam eder.
  Future<void> updatePhone(String newPhone) async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).update({
      'phone': newPhone,
    });
    currentPhone = newPhone;
    await _saveSession(currentUserId!, newPhone, currentUserName ?? '');
  }

  //Cihaza yaz
  //"Login/kayıt başarılı oldu, bu bilgiyi telefonun hafızasına yaz ki uygulama kapansa bile hatırlasın."

  Future<void> _saveSession(String userId, String phone, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_name', name);
    await prefs.setBool('is_logged_in', true);
  }
  // Oturum var mı?

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  //Kayıtlı oturumu yükle
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('user_id');
    currentPhone = prefs.getString('user_phone');
    currentUserName = prefs.getString('user_name');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    currentUserId = null;
    currentPhone = null;
    currentUserName = null;
  }
}
