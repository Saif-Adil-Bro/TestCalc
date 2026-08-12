import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_calculator/main.dart';

void main() {
  testWidgets('Calculator UI elements render successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });
}
