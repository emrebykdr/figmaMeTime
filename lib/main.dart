import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/home_page.dart';
import 'package:figmaap/pages/main_page.dart';
import 'package:figmaap/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final loggedIn = await UserService.isLoggedIn();
  if (loggedIn) {
    await UserService.loadSession();
  }

  runApp(MyApp(isLoggedIn: loggedIn));
}

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
      builder: (context, child) {
        Widget result = child!;
        if (kIsWeb) {
          result = MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(top: 41.42),
            ),
            child: result,
          );
        }
        return ResponsiveLayout(child: result);
      },
      home: isLoggedIn ? const MainPage() : const HomePage(),
    );
  }
}
