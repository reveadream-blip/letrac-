import 'package:flutter_test/flutter_test.dart';

import 'package:le_trace_magique/app.dart';

void main() {
  testWidgets('Home screen shows main mode buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const LeTraceMagiqueApp());
    await tester.pumpAndSettle();

    expect(find.text('Alphabet'), findsOneWidget);
    expect(find.text('Mes 1000 Mots'), findsOneWidget);
  });
}
