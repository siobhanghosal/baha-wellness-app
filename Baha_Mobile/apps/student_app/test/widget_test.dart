import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:student_app/src/ui/student_identity_screen.dart';

void main() {
  testWidgets('shows development identity prompt when no session exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentIdentityScreen(
          defaultExternalAuthId: '',
          defaultAuthEmail: '',
          apiBaseUrl: 'http://10.0.2.2:8000',
          onSubmit: _noop,
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Enter Student App'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Future<void> _noop(_) async {}
