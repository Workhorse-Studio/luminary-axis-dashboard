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

      // monthKeyToTermIndex expects "dd-MM-yyyy" or similar that monthKeyToTermIndex splits
      // Looking at utils.dart:
      // final tmp = monthKey.split('-').reversed.toList();
      // tmp[1] = tmp[1].padLeft(2, '0');
      // tmp[2] = tmp[2].padLeft(2, '0');
      // final String reversedMonthKey = tmp.join('-');
      // final dt = DateTime.parse(reversedMonthKey);
      
      // If monthKey is "05-10-2023"
      // reversed is ["2023", "10", "05"]
      // joined is "2023-10-05"
      // DateTime.parse works.
      
      expect(monthKeyToTermIndex(gs, '15-02-2023'), 0);
      expect(monthKeyToTermIndex(gs, '15-05-2023'), 1);
      expect(monthKeyToTermIndex(gs, '15-08-2023'), 1);
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
