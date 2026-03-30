import 'package:ferrybooking/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login form renders with required fields', (WidgetTester tester) async {
    await tester.pumpWidget(FerryBookingApp());

    expect(find.text('Ferry Booking Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('navigates to sign up screen', (WidgetTester tester) async {
    await tester.pumpWidget(FerryBookingApp());

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
