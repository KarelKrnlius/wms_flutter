import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wms_flutter/main.dart';
import 'package:wms_flutter/core/app_theme.dart';
import 'package:wms_flutter/core/responsive.dart';
import 'package:wms_flutter/screens/inbound/create_inbound_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

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

  for (final size in <Size>[
    const Size(320, 568),
    const Size(600, 960),
    const Size(1280, 800),
    const Size(1600, 900),
  ]) {
    testWidgets('receipt section never overlaps at ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: InboundReceiptSummary(
                itemNumber: 1,
                configured: false,
                noReceipt: false,
                receipt: '',
                onConfigure: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final summary = tester.getRect(
        find.byKey(const ValueKey('receipt-summary-1')),
      );
      final button = tester.getRect(
        find.byKey(const ValueKey('receipt-configure-1')),
      );
      expect(summary.contains(button.topLeft), isTrue);
      expect(summary.contains(button.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in <Size>[const Size(360, 2200), const Size(1600, 2200)]) {
    testWidgets('inbound adds Barang #2 below Barang #1 at ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const CreateInboundScreen(
            initialOptions: {
              'suppliers': [
                {'id': 'supplier-1', 'nama': 'Supplier Uji'},
              ],
              'items': [
                {
                  'sku': 'SKU-001',
                  'nama': 'Barang Uji',
                  'satuan': 'PCS',
                  'harga_dasar': 10000,
                },
              ],
              'racks': [
                {'id': 'rack-1', 'kode_rak': 'R-A1', 'sisa': 100},
              ],
              'units': ['PCS'],
              'categories': ['Elektronik', 'Peralatan Gudang'],
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Barang #1'), findsOneWidget);
      expect(find.text('Barang #2'), findsNothing);
      expect(find.text('Atur Resi'), findsOneWidget);

      await tester.tap(find.text('Tambah barang'));
      await tester.pumpAndSettle();

      expect(find.text('Barang #1'), findsOneWidget);
      expect(find.text('Barang #2'), findsOneWidget);
      expect(find.text('Atur Resi'), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Barang #2')).dy,
        greaterThan(tester.getTopLeft(find.text('Barang #1')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('inbound category can select existing or type a new value', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: const CreateInboundScreen(
          initialOptions: {
            'suppliers': [],
            'items': [],
            'racks': [],
            'units': ['PCS'],
            'categories': ['Elektronik', 'Peralatan Gudang'],
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Barang Baru'));
    await tester.pumpAndSettle();

    final categoryField = find.byKey(const ValueKey('inbound-category-1'));
    expect(categoryField, findsOneWidget);

    await tester.enterText(categoryField, 'elek');
    await tester.pumpAndSettle();
    expect(find.text('Elektronik'), findsOneWidget);

    await tester.tap(find.text('Elektronik'));
    await tester.pumpAndSettle();
    expect(find.text('Elektronik'), findsOneWidget);

    await tester.enterText(categoryField, 'Kategori Baru Sekolah');
    await tester.pump();
    expect(find.text('Kategori Baru Sekolah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
