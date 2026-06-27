import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/main.dart';

void main() {
  testWidgets('renders parent placeholder', (tester) async {
    await tester.pumpWidget(const ParentApp());
    expect(find.text('Parent app scaffolded'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
