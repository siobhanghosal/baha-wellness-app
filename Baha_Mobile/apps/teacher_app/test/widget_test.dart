import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_app/main.dart';

void main() {
  testWidgets('renders teacher placeholder', (tester) async {
    await tester.pumpWidget(const TeacherApp());
    expect(find.text('Teacher app scaffolded'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
