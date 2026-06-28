import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:parent_app/main.dart';

void main() {
  testWidgets('shows development identity prompt when no session exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ParentIdentityScreen(
          defaultExternalAuthId: '',
          defaultAuthEmail: '',
          apiBaseUrl: 'http://10.0.2.2:8000',
          onSubmit: _noop,
        ),
      ),
    );

    expect(find.text('Parent app bootstrap'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}

Future<void> _noop(_) async {}
