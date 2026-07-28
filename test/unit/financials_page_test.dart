import 'package:axis_dashboard/utils/financial_chart_scale.dart';
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
}
