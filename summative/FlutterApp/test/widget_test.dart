import 'package:flutter_test/flutter_test.dart';
import 'package:child_mortality_app/main.dart';

void main() {
  testWidgets('Renders Child Mortality prediction screen with Predict button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ChildMortalityApp());

    // Verify title and Predict button are rendered
    expect(find.text('Umoja Health Connect'), findsOneWidget);
    expect(find.text('Predict'), findsOneWidget);
    expect(find.text('Prediction Output Area'), findsOneWidget);
  });
}
