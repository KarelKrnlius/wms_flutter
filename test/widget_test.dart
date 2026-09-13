import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_flutter/main.dart';

void main() {
  testWidgets('WMS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WmsApp(isLoggedIn: false));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
