// 基本 smoke test。
//
// 注意：完整的 App（PokeBidApp）啟動需要先初始化 Supabase / Firebase，
// 不適合在純 widget test 裡 pump。這裡先放一個最小可過的健全性測試，
// 之後可針對個別不依賴後端的 widget 補測。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('基本 widget 能正常渲染', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: Text('TCGspot'))),
    ));

    expect(find.text('TCGspot'), findsOneWidget);
  });
}
