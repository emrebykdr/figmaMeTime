import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/home_page.dart';
import 'package:figmaap/pages/main_page.dart';
import 'package:figmaap/services/user_service.dart';
import 'package:figmaap/services/salon_service.dart';

// Uygulamanın giriş noktası. Flutter her platformda (mobil/web) burayı çalıştırır.
void main() async {
  // Firebase gibi native servisleri kullanmadan önce Flutter'ın hazır olmasını garanti eder.
  WidgetsFlutterBinding.ensureInitialized();
  // EmailJS Private Key gibi sırları .env'den okur (.env gitignore'da,
  // GitHub'a gitmiyor; bkz. .env.example). Ekstra bir çalıştırma bayrağı
  // gerekmez, normal 'flutter run' yeterlidir.
  await dotenv.load(fileName: ".env");
  // Firebase'i (Firestore, Auth vs. için) başlatır. firebase_options.dart platforma göre ayarları verir.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kullanıcının en son seçtiği şube (varsa) statik alanlara yüklenir.
  await SalonService.loadSession();

  // Cihazda daha önce kaydedilmiş bir oturum var mı diye bakar (SharedPreferences üzerinden).
  var loggedIn = await UserService.isLoggedIn();
  if (loggedIn) {
    // Varsa kullanıcı bilgilerini (id, telefon, isim) statik alanlara yükler.
    await UserService.loadSession();

    // Oturum cihazda kayıtlı olsa bile, hesap admin panelinden sonradan
    // "Hesabı Engelle" ile işaretlenmiş olabilir. Her açılışta kontrol
    // edilir; engelliyse oturum kapatılıp giriş ekranına düşülür.
    final userId = UserService.currentUserId;
    if (userId != null) {
      final userData = await UserService().getUserById(userId);
      if (userData?['accountBlocked'] == true) {
        await UserService.logout();
        loggedIn = false;
      }
    }
  }

  // Uygulamayı başlatır ve giriş durumunu MyApp'e parametre olarak geçer.
  runApp(MyApp(isLoggedIn: loggedIn));
}

// Uygulamanın kök widget'ı: tema, responsive ayarları ve hangi sayfanın
// açılacağını (home) burada belirliyoruz.
class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeTime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFDCCC5)),
      ),
      // Tüm sayfaları saran ortak wrapper. Ekran boyutuna göre ölçeklendirme
      // (ResponsiveLayout) ve web'de üstteki boşluğu (tarayıcı çubuğu vb.) düzeltme burada yapılır.
      builder: (context, child) {
        Widget result = child!;
        if (kIsWeb) {
          // Web'de tarayıcı kendi üst boşluğunu eklemediği için manuel bir
          // padding ekleyip tasarımın mobildeki gibi görünmesini sağlıyoruz.
          result = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(top: 41.42),
            ),
            child: result,
          );
        }
        return ResponsiveLayout(child: result);
      },
      // Açılış sayfası: giriş yapılmışsa MainPage, yapılmamışsa HomePage (login/sign up).
      // Admin paneli artık bu Flutter projesinin parçası değil, ayrı bir
      // HTML/CSS/JS web projesi olarak çalışacak.
      home: isLoggedIn ? const MainPage() : const HomePage(),
    );
  }
}
