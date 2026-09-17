import 'package:flutter_test/flutter_test.dart';
import 'package:wings_driver/main.dart';

void main() {
  testWidgets('Wings Driver App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WingsDriverApp());
    expect(find.text('Wings Driver | كابتن وينجز'), findsNothing);
  });
}
