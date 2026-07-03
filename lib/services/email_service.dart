import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// EmailJS (https://www.emailjs.com) üzerinden, herhangi bir backend veya
/// OAuth popup'ı gerektirmeden doğrudan mobil uygulamadan email gönderir.
/// Kullanıcı login_phone.dart'ta email girip "Continue"a bastığı anda kodu
/// otomatik göndermek için kullanılır (admin panelinde artık kişiye özel
/// email gönderimi yok, sadece ekranda gösterilen bir master kod var — bkz.
/// admin_web/shared/loginCode.js).
///
/// Kurulum:
/// 1. https://www.emailjs.com adresinde ücretsiz hesap aç.
/// 2. Bir email servisi bağla (Gmail/Outlook vb.) -> Service ID'yi kopyala.
/// 3. Bir email şablonu oluştur; şablon içinde {{to_email}}, {{to_name}},
///    {{code}} değişkenlerini kullan -> Template ID'yi kopyala.
/// 4. Account > General sayfasındaki Public Key'i kopyala.
/// 5. .env dosyasına EMAILJS_PRIVATE_KEY=... olarak Private Key'i ekle
///    (bkz. .env.example; .env gitignore'da, GitHub'a gitmiyor).
class EmailService {
  static const String serviceId = 'metimeservice';
  static const String templateId = 'template_jbaxsx4';
  static const String publicKey = '149THUurJIJuCotUX';

  static const String _endpoint =
      'https://api.emailjs.com/api/v1.0/email/send';

  // EmailJS hesabında "strict mode" (Account > Security > Allow API calls
  // from non-browser applications) açık olduğu için tarayıcı dışı
  // çağrılarda (mobil uygulama gibi) bu Private Key zorunlu. Uygulama
  // koduna gömülü olduğundan tersine mühendislikle çıkarılabilir; en kötü
  // ihtimalle EmailJS günlük gönderim kotası kötüye kullanılır (hesap ele
  // geçirilmez). Bilinçli kabul edilmiş bir risk.
  String? get _privateKey => dotenv.env['EMAILJS_PRIVATE_KEY'];

  bool get isConfigured => _privateKey != null && _privateKey!.isNotEmpty;

  /// Gönderim başarılıysa true döner. EmailJS henüz yapılandırılmadıysa veya
  /// istek başarısız olursa false döner ama hata fırlatmaz — kod zaten
  /// Firestore'a yazıldığı için admin panelinden manuel de gönderilebilir.
  Future<bool> sendLoginCode({
    required String toEmail,
    required String toName,
    required String code,
  }) async {
    if (!isConfigured) return false;

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'accessToken': _privateKey!,
          'template_params': {
            'to_email': toEmail,
            'to_name': toName,
            'code': code,
          },
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
