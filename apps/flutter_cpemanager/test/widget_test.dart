import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_cpemanager/main.dart';

void main() {
  testWidgets('renders mobile connection form', (tester) async {
    await tester.pumpWidget(const CpeManagerApp());

    expect(find.text('CPE Manager'), findsOneWidget);
    expect(find.text('连接'), findsOneWidget);
    expect(find.text('读取状态'), findsOneWidget);
  });
}
