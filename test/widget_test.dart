import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skripsiflow/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    expect(find.text('Selamat Datang di SkripsiFlow'), findsOneWidget);
    expect(find.text('Email Kampus'), findsOneWidget);
  });
}
