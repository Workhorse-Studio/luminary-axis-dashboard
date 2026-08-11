import 'dart:async';

import 'package:axis_dashboard/main.dart';
import 'package:axis_dashboard/utils/financial_chart_scale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinancialChartScale', () {
    test('uses a readable interval for high-value financial data', () {
      final scale = FinancialChartScale.fromValues([
        269848.50,
        10150.00,
      ]);

      expect(scale.minY, 0);
      expect(scale.maxY, 300000);
      expect(scale.interval, 50000);
      expect((scale.maxY - scale.minY) / scale.interval, lessThanOrEqualTo(7));
    });

    test('keeps losses inside the net-profit chart range', () {
      final scale = FinancialChartScale.fromValues([
        -5000,
        259698.50,
      ]);

      expect(scale.minY, -50000);
      expect(scale.maxY, 300000);
      expect(scale.interval, 50000);
    });

    test('provides a valid range when every value is zero', () {
      final scale = FinancialChartScale.fromValues([0, 0]);

      expect(scale.minY, 0);
      expect(scale.maxY, 1);
      expect(scale.interval, 1);
    });
  });

  group('calculatePaidFinancialData', () {
    test('adds post-baseline fulfilled inflows and ignores outflows', () {
      final result = calculatePaidFinancialData(<JSON>[
        _invoice(
          type: 'student',
          status: InvoiceStatus.paymentReceived,
          date: '06-08-2026',
          amount: 250,
        ),
        _invoice(
          type: 'student',
          status: InvoiceStatus.pendingPayment,
          date: '7-8-2026',
          amount: 999,
        ),
        _invoice(
          type: 'teacher',
          status: InvoiceStatus.paymentReceived,
          date: '10-08-2026',
          amount: 80.5,
        ),
        _invoice(
          type: 'student',
          status: InvoiceStatus.paymentReceived,
          date: '01-01-2025',
          amount: 400,
        ),
      ], year: 2026);

      expect(result.ytdInflows, financialRevenueBaseline2026 + 250);
      expect(result.ytdOutflows, 0);
      expect(result.ytdNetCashFlow, financialRevenueBaseline2026 + 250);
      expect(result.monthlyData, hasLength(2));
      expect(result.monthlyData.first.month, 7);
      expect(result.monthlyData.first.inflows, financialRevenueBaseline2026);
      expect(result.monthlyData.last.month, 8);
      expect(result.monthlyData.last.inflows, 250);
      expect(result.monthlyData.last.outflows, 0);
      expect(result.yearlyData.map((item) => item.year), [2025, 2026]);
      expect(
        result.yearlyData.last.inflows,
        financialRevenueBaseline2026 + 250,
      );
    });

    test('keeps the 30 July baseline from double-counting old invoices', () {
      final result = calculatePaidFinancialData(<JSON>[
        <String, Object?>{
          'invoiceStatus': InvoiceStatus.paymentReceived.name,
          'invoiceDate': Timestamp.fromDate(DateTime(2026, 2, 3)),
          'amtPayable': 75,
        },
        <String, Object?>{
          'invoiceStatus': InvoiceStatus.paymentReceived.name,
          'invoiceDateFormatted': 'not-a-date',
          'invoiceType': 'teacher',
          'amtDue': 100,
        },
        <String, Object?>{
          'invoiceStatus': InvoiceStatus.paymentReceived.name,
          'invoiceDateFormatted': '03-02-2026',
          'invoiceType': 'student',
          'amtPayable': 'invalid',
        },
      ], year: 2026);

      expect(result.ytdInflows, financialRevenueBaseline2026);
      expect(result.ytdOutflows, 0);
      expect(result.monthlyData.single.month, 7);
      expect(result.monthlyData.single.includesRevenueBaseline, isTrue);
      expect(result.yearlyData.single.inflows, financialRevenueBaseline2026);
    });
  });

  test(
    'paid financial stream refreshes when an invoice becomes paid',
    () async {
      final database = FakeFirebaseFirestore();
      const year = 2026;
      final invoices = database
          .collection('global')
          .doc('archives')
          .collection('invoices');
      await invoices
          .doc('student-paid')
          .set(
            _invoice(
              type: 'student',
              status: InvoiceStatus.paymentReceived,
              date: '06-08-$year',
              amount: 100,
            ),
          );
      await invoices
          .doc('teacher-paid')
          .set(
            _invoice(
              type: 'teacher',
              status: InvoiceStatus.paymentReceived,
              date: '06-08-$year',
              amount: 40,
            ),
          );
      await invoices
          .doc('student-pending')
          .set(
            _invoice(
              type: 'student',
              status: InvoiceStatus.pendingPayment,
              date: '06-08-$year',
              amount: 900,
            ),
          );

      final iterator = StreamIterator<FinancialData>(
        watchPaidFinancialData(database: database, year: year),
      );
      expect(await iterator.moveNext(), isTrue);
      expect(
        iterator.current.ytdInflows,
        financialRevenueBaseline2026 + 100,
      );
      expect(iterator.current.ytdOutflows, 0);

      await invoices.doc('student-pending').update(<String, Object?>{
        'invoiceStatus': InvoiceStatus.paymentReceived.name,
      });
      expect(await iterator.moveNext(), isTrue);
      expect(
        iterator.current.ytdInflows,
        financialRevenueBaseline2026 + 1000,
      );
      expect(iterator.current.ytdOutflows, 0);
      expect(
        iterator.current.ytdNetCashFlow,
        financialRevenueBaseline2026 + 1000,
      );
      await iterator.cancel();
    },
  );

  testWidgets('financial KPI cards label paid cash movement clearly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinancialKpiCards(
            financialData: FinancialData(
              ytdInflows: 1000,
              ytdOutflows: 40,
              monthlyData: const <MonthlyFinancials>[],
            ),
          ),
        ),
      ),
    );

    expect(find.text('YTD Paid Inflows'), findsOneWidget);
    expect(find.text('YTD Paid Outflows'), findsOneWidget);
    expect(find.text('YTD Net Cash Flow'), findsOneWidget);
    expect(find.text(r'$1000.00'), findsOneWidget);
    expect(find.text(r'$40.00'), findsOneWidget);
    expect(find.text(r'$960.00'), findsOneWidget);
  });

  testWidgets('financial KPI cards stack without overflowing on narrow views', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinancialKpiCards(
            financialData: FinancialData(
              ytdInflows: 1000,
              ytdOutflows: 0,
              monthlyData: const <MonthlyFinancials>[],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AxisCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    for (final card in find.byType(AxisCard).evaluate()) {
      expect(tester.getSize(find.byWidget(card.widget)).width, 600);
    }
  });

  testWidgets('charts fill the viewport, scroll, and switch breakdowns', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(720, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final july = MonthlyFinancials(7)
      ..inflows = financialRevenueBaseline2026
      ..includesRevenueBaseline = true;
    final august = MonthlyFinancials(8)..inflows = 1200;
    final year2025 = YearlyFinancials(2025)..inflows = 300000;
    final year2026 = YearlyFinancials(2026)
      ..inflows = financialRevenueBaseline2026 + 1200
      ..includesRevenueBaseline = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FinancialsCharts(
            financialData: FinancialData(
              ytdInflows: financialRevenueBaseline2026 + 1200,
              ytdOutflows: 0,
              monthlyData: <MonthlyFinancials>[july, august],
              yearlyData: <YearlyFinancials>[year2025, year2026],
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('financial-bar-chart-panel')))
          .width,
      720,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('financial-line-chart-panel')))
          .width,
      720,
    );
    final barScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('bar-chart-scroll')),
    );
    expect(barScroll.scrollDirection, Axis.horizontal);
    await tester.drag(
      find.byKey(const ValueKey('bar-chart-scroll')),
      const Offset(-400, 0),
    );
    await tester.pump();
    expect(barScroll.controller!.offset, greaterThan(0));

    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('bar-monthly')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('bar-yearly')));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('bar-yearly')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('line-monthly')))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}

JSON _invoice({
  required String type,
  required InvoiceStatus status,
  required String date,
  required num amount,
}) => <String, Object?>{
  'invoiceType': type,
  'invoiceStatus': status.name,
  'invoiceDateFormatted': date,
  if (type == 'student') 'amtPayable': amount,
  if (type == 'teacher') 'amtDue': amount,
};
