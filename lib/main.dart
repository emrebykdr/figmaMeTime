import 'package:flutter/material.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeTime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFDCCC5)),
      ),
      builder: (context, child) {
        final isWide =
            MediaQuery.of(context).size.width > Responsive.maxAppWidth;
        if (!isWide) return child!;

        return ColoredBox(
          color: const Color(0xFFE0E0E0),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: Responsive.maxAppWidth,
                height: Responsive.maxAppHeight,
                child: child,
              ),
            ),
          ),
        );
      },
      home: const HomePage(),
    );
  }
}
