import 'package:flutter_test/flutter_test.dart';
import 'package:baha_ui_prototype/main.dart';

void main() {
  testWidgets('BAHA UI prototype starts', (tester) async {
    await tester.pumpWidget(const BahaUiPrototypeApp());
    await tester.pump();
    expect(find.text('BAHA Wellness'), findsOneWidget);
  });
}
