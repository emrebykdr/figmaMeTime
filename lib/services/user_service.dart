import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:figmaap/services/salon_service.dart';

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

  /// Yeni bir 5 haneli giriş kodu üretir ve Firestore'a (loginCode +
  /// loginCodeExpiresAt, 10 dk geçerli) yazar. Mobil tarafta
  /// login_phone.dart, kullanıcı email girip devam ettiğinde bunu otomatik
  /// tetikler.
  Future<String> issueLoginCode(String userId) async {
    final code = (10000 + Random().nextInt(90000)).toString();
    final expiresAt = DateTime.now().millisecondsSinceEpoch + 10 * 60 * 1000;
    await _firestore.collection('users').doc(userId).update({
      'loginCode': code,
      'loginCodeExpiresAt': expiresAt,
    });
    return code;
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

  /// Bir email zaten BAŞKA bir hesapta doğrulanmışsa (bkz.
  /// account_settings_page.dart'taki "Verify this email") true döner. Kayıt
  /// sırasında aynı doğrulanmış email ile ikinci bir hesap açılmasını
  /// engellemek için sign_up.dart bunu kontrol eder.
  Future<bool> isEmailVerifiedElsewhere(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .where('emailVerified', isEqualTo: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Hesap Ayarları'ndan email doğrulaması için 5 haneli bir kod üretir ve
  /// Firestore'a yazar. loginCode'dan ayrı bir alanda tutulur ki kullanıcı
  /// aynı anda aktif bir giriş kodu varsa onunla çakışmasın.
  Future<String> issueEmailVerificationCode(String userId) async {
    final code = (10000 + Random().nextInt(90000)).toString();
    final expiresAt = DateTime.now().millisecondsSinceEpoch + 10 * 60 * 1000;
    await _firestore.collection('users').doc(userId).update({
      'emailVerificationCode': code,
      'emailVerificationCodeExpiresAt': expiresAt,
    });
    return code;
  }

  /// Girilen kod, süresi dolmamış üretilen kodla eşleşiyorsa emailVerified
  /// alanını true yapar ve true döner; eşleşmiyorsa/süresi dolmuşsa false
  /// döner (Firestore'a hiçbir şey yazılmaz).
  Future<bool> confirmEmailVerification(String userId, String code) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return false;

    final expected = data['emailVerificationCode'] as String?;
    final expiresAt = data['emailVerificationCodeExpiresAt'] as int?;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (expected == null || expected != code) return false;
    if (expiresAt == null || now > expiresAt) return false;

    await _firestore.collection('users').doc(userId).update({
      'emailVerified': true,
    });
    return true;
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

  /// Dashboard'da (admin_web/app.js -> "Kod Oluştur", kullanıcı seçilmeden)
  /// üretilen TEK evrensel kod: herhangi bir hesabın giriş kodu ekranında
  /// girilirse, o kişisel loginCode'a ek olarak bu da kabul edilir —
  /// destek/test amaçlı bir yedek. adminConfig/masterCode dokümanında
  /// tutulur (bkz. admin_web/shared/loginCode.js -> generateMasterCode).
  Stream<Map<String, dynamic>?> watchMasterCode() {
    return _firestore
        .collection('adminConfig')
        .doc('masterCode')
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Giriş yapmış kullanıcının kendi dokümanını canlı dinler. main_page.dart
  /// bunu iki amaçla kullanır: (1) accountBlocked anında yakalanır (admin
  /// panelden hesap engellenirse uygulama açıkken bile oturum kapatılır —
  /// main.dart'taki kontrol sadece açılışta çalışıyordu), (2) Hesap
  /// Ayarları'nda (veya admin panelinden) isim/email/telefon değişirse
  /// "Hello, İsim" gibi alanlar anında güncellenir; sayfa yeniden açılmayı
  /// beklemez.
  Stream<Map<String, dynamic>?> watchCurrentUser() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.data());
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

  /// Hesap Ayarları sayfasından ad/email/telefon güncellemesi. currentUserId
  /// sabit kaldığı için geçmiş randevular bağlı kalmaya devam eder.
  /// [resetEmailVerification] true geçilirse (email daha önce doğrulanmış
  /// bir değerden farklı bir değere değiştirildiyse) emailVerified false'a
  /// çekilir — eski doğrulama yeni email için geçerli sayılmaz.
  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    bool resetEmailVerification = false,
  }) async {
    if (currentUserId == null) return;
    final data = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'phone': phone,
    };
    if (resetEmailVerification) {
      data['emailVerified'] = false;
    }
    await _firestore.collection('users').doc(currentUserId).update(data);
    currentUserName = fullName;
    currentPhone = phone;
    await _saveSession(currentUserId!, phone, fullName);
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
    // prefs.clear() salon_id/salon_name'i de siliyor ama SalonService'in
    // bellekteki static alanlarına dokunmuyor; bu yüzden burada da elle
    // temizlenmezse çıkış yapılmış olsa bile eski şube seçili kalır ve
    // misafir akışındaki şube seçim ekranı (branch_picker_page.dart)
    // "zaten seçili" sanıp atlanır.
    SalonService.currentSalonId = null;
    SalonService.currentSalonName = null;
  }
}
