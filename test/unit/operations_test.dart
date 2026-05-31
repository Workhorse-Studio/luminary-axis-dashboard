import 'package:flutter_test/flutter_test.dart';
import 'package:axis_dashboard/main.dart';

void main() {
  group('Operations Tests', () {
    test('TeacherPayout rate calculation', () {
      expect(TeacherPayout.calculateRate(50), 25);
      expect(TeacherPayout.calculateRate(150), 30);
      expect(TeacherPayout.calculateRate(400), 35);
      expect(TeacherPayout.calculateRate(600), 38);
    });

    test('TeacherPayout final payout calculation', () {
      expect(TeacherPayout.calculateFinalPayout(10), 250);
      expect(TeacherPayout.calculateFinalPayout(200), 6000);
    });

    test('StudentAttendanceStore.invoicePayloadMatches', () {
      final entries = [
        (amt: 190.0, desc: 'Class A', qty: 2, rate: 95.0),
      ];
      final a = StudentInvoiceData(
        invoiceDateFormatted: '01-01-2023',
        address: 'Addr',
        amtPayable: 190.0,
        dueDateFormatted: '08-01-2023',
        entries: entries,
        invoiceId: 'ID1',
        parentName: 'Parent',
        studentName: 'Student',
        invoiceStatus: InvoiceStatus.pendingPayment,
        terms: 'Term 1',
      );

      final b = StudentInvoiceData(
        invoiceDateFormatted: '01-01-2023',
        address: 'Addr',
        amtPayable: 190.0,
        dueDateFormatted: '08-01-2023',
        entries: entries,
        invoiceId: 'ID1',
        parentName: 'Parent',
        studentName: 'Student',
        invoiceStatus: InvoiceStatus.pendingPayment,
        terms: 'Term 1',
      );

      expect(StudentAttendanceStore.invoicePayloadMatches(a, b), isTrue);

      final c = StudentInvoiceData(
        invoiceDateFormatted: '01-01-2023',
        address: 'Addr',
        amtPayable: 200.0, // Different amt
        dueDateFormatted: '08-01-2023',
        entries: entries,
        invoiceId: 'ID1',
        parentName: 'Parent',
        studentName: 'Student',
        invoiceStatus: InvoiceStatus.pendingPayment,
        terms: 'Term 1',
      );
      expect(StudentAttendanceStore.invoicePayloadMatches(a, c), isFalse);
    });

    test('Map/List extension utilities', () {
      final List<int> list = [1, 2];
      list.ensureLength(2, map: 0);
      expect(list.length, 3);
      expect(list[2], 0);

      final Map<String, int> map = {'a': 1};
      expect(map.accessOrElse('a', orElse: 2), 1);
      expect(map.accessOrElse('b', orElse: 2), 2);
      expect(map['b'], 2);

      map.ensureKey('c', map: 3);
      expect(map['c'], 3);
      map.ensureKey('a', map: 5); // Should not overwrite
      expect(map['a'], 1);
    });
  });
}
