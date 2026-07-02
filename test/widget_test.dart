import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:figmaap/main.dart';

void main() {
  testWidgets('MyApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
