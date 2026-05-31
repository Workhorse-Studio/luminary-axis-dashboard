import 'package:axis_dashboard/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoicingPageState teacher month selection', () {
    test('defaults selected teacher month to current month', () {
      final now = DateTime.now();
      final state = InvoicingPageState();

      expect(state.selectedTeacherMonthId, '${now.month}-${now.year}');
    });

    test('generateMonthIds for current year only includes elapsed months', () {
      final now = DateTime.now();
      final state = InvoicingPageState()..year = now.year;

      final monthIds = state.generateMonthIds();

      expect(monthIds.length, now.month);
      expect(monthIds.first, '1-${now.year}');
      expect(monthIds.last, '${now.month}-${now.year}');
    });

    test('generateMonthIds for past year includes all 12 months', () {
      final now = DateTime.now();
      final state = InvoicingPageState()..year = now.year - 1;

      final monthIds = state.generateMonthIds();

      expect(monthIds.length, 12);
      expect(monthIds.first, '1-${now.year - 1}');
      expect(monthIds.last, '12-${now.year - 1}');
    });

    test('selectedTeacherMonthIdForYear keeps selected month when valid', () {
      final now = DateTime.now();
      final state = InvoicingPageState()
        ..year = now.year - 1
        ..selectedTeacherMonthId = '3-${now.year - 1}';

      expect(state.selectedTeacherMonthIdForYear(), '3-${now.year - 1}');
    });

    test('selectedTeacherMonthIdForYear falls back to current month', () {
      final now = DateTime.now();
      final state = InvoicingPageState()
        ..year = now.year
        ..selectedTeacherMonthId = '12-${now.year - 1}';

      expect(state.selectedTeacherMonthIdForYear(), '${now.month}-${now.year}');
    });

    test(
      'syncSelectedTeacherMonthIdForYear aligns selection to selected year',
      () {
        final now = DateTime.now();
        final state = InvoicingPageState()
          ..year = now.year - 1
          ..selectedTeacherMonthId = '${now.month}-${now.year}';

        state.syncSelectedTeacherMonthIdForYear();

        expect(state.selectedTeacherMonthId, '12-${now.year - 1}');
      },
    );

    test('formatMonthIdLabel formats month labels consistently', () {
      final state = InvoicingPageState();

      expect(state.formatMonthIdLabel('5-2026'), 'May 2026');
      expect(state.formatMonthIdLabel('11-2025'), 'November 2025');
    });
  });
}
