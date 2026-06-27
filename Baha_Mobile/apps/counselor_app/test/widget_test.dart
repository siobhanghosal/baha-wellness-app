import 'package:counselor_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders counselor placeholder', (tester) async {
    await tester.pumpWidget(const CounselorApp());
    expect(find.text('Counselor app scaffolded'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
