import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_flutter/main.dart';
import 'package:wms_flutter/core/responsive.dart';

void main() {
  testWidgets('WMS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WmsApp(isLoggedIn: false));
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  for (final scenario in <(double, AppFormFactor)>[
    (320, AppFormFactor.mobile),
    (360, AppFormFactor.mobile),
    (390, AppFormFactor.mobile),
    (430, AppFormFactor.mobile),
    (600, AppFormFactor.tablet),
    (900, AppFormFactor.tablet),
    (1440, AppFormFactor.desktop),
  ]) {
    testWidgets('uses ${scenario.$2.name} layout at ${scenario.$1}px', (
      tester,
    ) async {
      late AppFormFactor actual;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(scenario.$1, 900)),
            child: Builder(
              builder: (context) {
                actual = context.formFactor;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(actual, scenario.$2);
    });
  }

  for (final size in <Size>[
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(430, 932),
    const Size(600, 960),
  ]) {
    testWidgets('login remains usable without overflow at ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const WmsApp(isLoggedIn: false));
      await tester.pump();

      expect(find.text('Masuk ke Sistem'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
