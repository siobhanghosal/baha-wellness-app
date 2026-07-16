import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:student_app/src/prototype/app_theme.dart';
import 'package:student_app/src/prototype/prototype_models.dart';
import 'package:student_app/src/prototype/theme_manager.dart';
import 'package:student_app/src/ui/student_identity_screen.dart';
import 'package:student_app/src/ui/student_ready_screen.dart';

void main() {
  testWidgets(
    'shows unified role-first identity prompt when no session exists',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StudentIdentityScreen(
            defaultExternalAuthId: '',
            defaultPassword: '',
            apiBaseUrl: 'http://10.0.2.2:8000',
            onSubmit: _noop,
          ),
        ),
      );

      expect(find.text('One app, role-based experience'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('breathing tool starts immediately and shows active controls', (
    tester,
  ) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _toolHarness(
        StudentLocalToolScreen(
          palette: studentPalette(StudentAgeGroup.teen, StudentGender.female),
          item: const UiCardItem(
            title: 'Calm Breathing',
            subtitle: 'A guided local reset.',
            tag: '1 min',
            icon: Icons.air_rounded,
            color: Color(0xFF3B82F6),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Start breathing reset'));
    await tester.tap(find.text('Start breathing reset'));
    await tester.pump();

    expect(find.text('Stop breathing reset'), findsOneWidget);
    expect(find.text('60 seconds left'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('comet sequence tool renders playable memory game shell', (
    tester,
  ) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _toolHarness(
        StudentLocalToolScreen(
          palette: studentPalette(StudentAgeGroup.teen, StudentGender.female),
          item: const UiCardItem(
            title: 'Comet Sequence',
            subtitle: 'Memory game.',
            tag: 'Memory',
            icon: Icons.auto_awesome_rounded,
            color: Color(0xFF8B5CF6),
          ),
        ),
      ),
    );

    expect(find.text('Watch. Remember. Repeat.'), findsOneWidget);
    expect(find.text('Start sequence'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('focus catch tool starts a playable round', (tester) async {
    _setLargeSurface(tester);
    await tester.pumpWidget(
      _toolHarness(
        StudentLocalToolScreen(
          palette: studentPalette(StudentAgeGroup.teen, StudentGender.female),
          item: const UiCardItem(
            title: 'Focus Catch',
            subtitle: 'Reaction game.',
            tag: 'Reflex',
            icon: Icons.ads_click_rounded,
            color: Color(0xFFF97316),
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Start focus round'));
    await tester.tap(find.text('Start focus round'));
    await tester.pump();

    expect(find.text('Stop focus round'), findsOneWidget);
    expect(find.text('20s'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

Widget _toolHarness(Widget child) {
  return MaterialApp(
    home: ThemeScope(controller: ThemeController(), child: child),
  );
}

void _setLargeSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<String?> _noop(Object? _, Object? mode) async => null;
