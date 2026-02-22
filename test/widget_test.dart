import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_calc/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const CryptographyApp());
    await tester.pumpAndSettle();
    expect(find.byType(CryptographyApp), findsOneWidget);
  });
}
