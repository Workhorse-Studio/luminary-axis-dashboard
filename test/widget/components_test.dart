import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:axis_dashboard/main.dart';

void main() {
  group('AxisButton Widget Tests', () {
    testWidgets('AxisButton.text renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AxisButton.text(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('AxisButton triggers onPressed', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AxisButton.text(
              label: 'Test Button',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Button'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('AxisButton is disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AxisButton.text(
              label: 'Disabled Button',
              onPressed: null,
            ),
          ),
        ),
      );

      final AxisButtonState state = tester.state(find.byType(AxisButton));
      expect(state.enabled, isFalse);
    });

    testWidgets('InvoiceWidget renders student invoice data', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2000, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = StudentInvoiceData(
        invoiceDateFormatted: '01-01-2023',
        address: '123 Test St',
        amtPayable: 190.0,
        dueDateFormatted: '08-01-2023',
        entries: [
          (amt: 190.0, desc: 'Math Class', qty: 2, rate: 95.0),
        ],
        invoiceId: 'INV-001',
        parentName: 'Parent Name',
        studentName: 'Student Name',
        invoiceStatus: InvoiceStatus.pendingPayment,
        terms: 'Term 1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvoiceWidget(
              studentInvoiceData: data,
              total: 190.0,
            ),
          ),
        ),
      );

      expect(find.text('TAX INVOICE'), findsOneWidget);
      expect(find.text('# INV-001'), findsOneWidget);
      expect(find.text('Math Class'), findsOneWidget);
      expect(find.text('SGD 190.00'), findsOneWidget);
    });
  });
}
