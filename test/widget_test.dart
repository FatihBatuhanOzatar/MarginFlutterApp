import 'package:flutter_test/flutter_test.dart';

import 'package:margin/main.dart';

void main() {
  testWidgets('App boots and shows the brand mark', (tester) async {
    await tester.pumpWidget(const MarginApp());
    expect(find.text('MARGIN'), findsOneWidget);
  });
}
