// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_assistant_app/main.dart';

void main() {
  testWidgets('starts on registration screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Registration'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
  });

  testWidgets('registration continues to mode chooser', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(
      find.byType(EditableText).at(0),
      'manas@example.com',
    );
    await tester.enterText(find.byType(EditableText).at(1), 'secret123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your workspace'), findsOneWidget);
    expect(find.text('Student Mode'), findsOneWidget);
    expect(find.text('Professional Mode'), findsOneWidget);
  });
}
