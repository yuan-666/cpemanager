import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_cpemanager/main.dart';

void main() {
  testWidgets('renders dashboard workspaces and navigation', (tester) async {
    await tester.pumpWidget(const CpeManagerApp());

    expect(find.text('NR 主小区'), findsWidgets);
    expect(find.text('PCC'), findsOneWidget);
    expect(find.text('载波聚合'), findsOneWidget);
    expect(find.text('锁频'), findsOneWidget);
    expect(find.text('速率'), findsOneWidget);
    expect(find.text('烽火'), findsOneWidget);

    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.text('设备登录'), findsOneWidget);
    expect(find.text('读取状态'), findsOneWidget);
  });
}
