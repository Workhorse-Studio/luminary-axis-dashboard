import 'package:flutter_test/flutter_test.dart';
import 'package:axis_dashboard/main.dart';

void main() {
  group('Utils Tests', () {
    test('generateId returns a string of length 16', () {
      final id = generateId();
      expect(id.length, 16);
    });

    test('generateId returns different IDs', () {
      final id1 = generateId();
      final id2 = generateId();
      expect(id1, isNot(equals(id2)));
    });

    test('monthKeyToTermIndex correctly maps month keys', () {
      final gs = GlobalState(
        currentTermNum: 0,
        terms: [
          TermData(
            termName: 'Term 1',
            termStartDate: DateTime(2023, 1, 1).millisecondsSinceEpoch,
            termEndDate: DateTime(2023, 3, 31).millisecondsSinceEpoch,
          ),
          TermData(
            termName: 'Term 2',
            termStartDate: DateTime(2023, 4, 1).millisecondsSinceEpoch,
            termEndDate: DateTime(2023, 6, 30).millisecondsSinceEpoch,
          ),
        ],
      );

      expect(monthKeyToTermIndex(gs, '15-02-2023'), 0);
      expect(monthKeyToTermIndex(gs, '15-05-2023'), 1);
      expect(monthKeyToTermIndex(gs, '15-08-2023'), 1);
    });

    test('attendanceBaseDateKey supports legacy and session keys', () {
      expect(attendanceBaseDateKey('14-5-2026'), '14-5-2026');
      expect(attendanceBaseDateKey('14-5-2026__s002'), '14-5-2026');
    });

    test('attendanceSessionNumber/sessionLabel parse correctly', () {
      expect(attendanceSessionNumber('14-5-2026'), 1);
      expect(attendanceSessionNumber('14-5-2026__s001'), 1);
      expect(attendanceSessionNumber('14-5-2026__s010'), 10);
      expect(attendanceSessionNumber('14-5-2026__sabc'), 1);
      expect(attendanceSessionLabel('14-5-2026__s003'), 'S3');
    });

    test('buildAttendanceSessionKey produces expected format', () {
      final key = buildAttendanceSessionKey(
        date: DateTime(2026, 5, 14),
        sessionNumber: 2,
      );
      expect(key, '14-5-2026__s002');
    });

    test('attendanceKeyToDateTime parses legacy and session keys', () {
      final a = attendanceKeyToDateTime('9-12-2026');
      final b = attendanceKeyToDateTime('9-12-2026__s004');
      expect(a, DateTime(2026, 12, 9));
      expect(b, DateTime(2026, 12, 9));
    });

    test('attendanceKeyMatchesDate works with session keys', () {
      final date = DateTime(2026, 5, 14);
      expect(attendanceKeyMatchesDate('14-5-2026__s001', date), isTrue);
      expect(attendanceKeyMatchesDate('15-5-2026__s001', date), isFalse);
    });

    test('compareAttendanceKeys sorts by date then session', () {
      final keys = [
        '14-5-2026__s002',
        '13-5-2026__s003',
        '14-5-2026__s003',
        '14-5-2026',
      ]..sort(compareAttendanceKeys);
      expect(
        keys,
        [
          '13-5-2026__s003',
          '14-5-2026',
          '14-5-2026__s002',
          '14-5-2026__s003',
        ],
      );
    });

    test('nextAttendanceSessionNumberForDate respects max for that day', () {
      final next = nextAttendanceSessionNumberForDate([
        '14-5-2026__s001',
        '14-5-2026__s005',
        '13-5-2026__s099',
      ], DateTime(2026, 5, 14));
      expect(next, 6);
    });

    test('nextAttendanceSessionNumberForDate defaults to 1', () {
      final next = nextAttendanceSessionNumberForDate(
        const [],
        DateTime(2026, 5, 14),
      );
      expect(next, 1);
    });

    test('attendanceMonthId supports legacy and session keys', () {
      expect(attendanceMonthId('14-5-2026'), '5-2026');
      expect(attendanceMonthId('14-5-2026__s010'), '5-2026');
    });

    test('monthKeyToTermIndex supports session keys and boundaries', () {
      final gs = GlobalState(
        currentTermNum: 0,
        terms: [
          TermData(
            termName: 'T1',
            termStartDate: DateTime(2026, 1, 1).millisecondsSinceEpoch,
            termEndDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
          ),
          TermData(
            termName: 'T2',
            termStartDate: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            termEndDate: DateTime(2026, 6, 30).millisecondsSinceEpoch,
          ),
        ],
      );
      expect(monthKeyToTermIndex(gs, '31-3-2026__s003'), 0);
      expect(monthKeyToTermIndex(gs, '1-4-2026__s001'), 1);
      expect(monthKeyToTermIndex(gs, '1-12-2026__s001'), 1);
    });

    test(
      'rebuildTermsAfterEndDateChange pulls later terms earlier to close gaps',
      () {
        final terms = [
          TermData(
            termName: 'T1',
            termStartDate: DateTime(2026, 1, 1).millisecondsSinceEpoch,
            termEndDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
          ),
          TermData(
            termName: 'T2',
            termStartDate: DateTime(2026, 4, 1).millisecondsSinceEpoch,
            termEndDate: DateTime(2026, 6, 30).millisecondsSinceEpoch,
          ),
          TermData(
            termName: 'T3',
            termStartDate: DateTime(2026, 7, 1).millisecondsSinceEpoch,
            termEndDate: DateTime(2026, 9, 30).millisecondsSinceEpoch,
          ),
        ];

        final updated = rebuildTermsAfterEndDateChange(
          terms: terms,
          currentTabIndex: 0,
          newEndDateMillis: DateTime(2026, 3, 15).millisecondsSinceEpoch,
        );
        final shiftMillis =
            DateTime(2026, 3, 15).millisecondsSinceEpoch -
            terms[1].termStartDate +
            1000;

        expect(updated.map((term) => term.termName), ['T1', 'T2', 'T3']);
        expect(updated[1].termStartDate, terms[1].termStartDate + shiftMillis);
        expect(updated[1].termEndDate, terms[1].termEndDate + shiftMillis);
        expect(updated[2].termStartDate, terms[2].termStartDate + shiftMillis);
        expect(updated[2].termEndDate, terms[2].termEndDate + shiftMillis);
      },
    );

    test('rebuildTermsAfterEndDateChange shifts later terms on overlap', () {
      final terms = [
        TermData(
          termName: 'T1',
          termStartDate: DateTime(2026, 1, 1).millisecondsSinceEpoch,
          termEndDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
        ),
        TermData(
          termName: 'T2',
          termStartDate: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          termEndDate: DateTime(2026, 6, 30).millisecondsSinceEpoch,
        ),
        TermData(
          termName: 'T3',
          termStartDate: DateTime(2026, 7, 1).millisecondsSinceEpoch,
          termEndDate: DateTime(2026, 9, 30).millisecondsSinceEpoch,
        ),
      ];
      final newEndDateMillis = DateTime(2026, 4, 3).millisecondsSinceEpoch;

      final updated = rebuildTermsAfterEndDateChange(
        terms: terms,
        currentTabIndex: 0,
        newEndDateMillis: newEndDateMillis,
      );
      final shiftMillis = newEndDateMillis - terms[1].termStartDate + 1000;

      expect(updated.map((term) => term.termName), ['T1', 'T2', 'T3']);
      expect(updated[1].termStartDate, terms[1].termStartDate + shiftMillis);
      expect(updated[1].termEndDate, terms[1].termEndDate + shiftMillis);
      expect(updated[2].termStartDate, terms[2].termStartDate + shiftMillis);
    });

    test('rebuildTermsAfterEndDateChange leaves the last term isolated', () {
      final terms = [
        TermData(
          termName: 'T1',
          termStartDate: DateTime(2026, 1, 1).millisecondsSinceEpoch,
          termEndDate: DateTime(2026, 3, 31).millisecondsSinceEpoch,
        ),
        TermData(
          termName: 'T2',
          termStartDate: DateTime(2026, 4, 1).millisecondsSinceEpoch,
          termEndDate: DateTime(2026, 6, 30).millisecondsSinceEpoch,
        ),
      ];

      final updated = rebuildTermsAfterEndDateChange(
        terms: terms,
        currentTabIndex: 1,
        newEndDateMillis: DateTime(2026, 6, 15).millisecondsSinceEpoch,
      );

      expect(updated[0].termStartDate, terms[0].termStartDate);
      expect(updated[0].termEndDate, terms[0].termEndDate);
      expect(
        updated[1].termEndDate,
        DateTime(2026, 6, 15).millisecondsSinceEpoch,
      );
    });

    test('DateUtils extension tests', () {
      final dt = DateTime(2023, 10, 5, 14, 30, 45);
      expect(dt.toTimestampStringShort(), '05-10-2023');
      expect(dt.toTimestampString(), '05-10-2023 14:30:45');

      final dt2 = DateTime(2023, 10, 5, 10, 0, 0);
      expect(dt.isSameDayAs(dt2), isTrue);

      final dt3 = DateTime(2023, 10, 6);
      expect(dt.isSameDayAs(dt3), isFalse);
    });
  });
}
