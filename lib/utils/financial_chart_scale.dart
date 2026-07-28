import 'dart:math';

class FinancialChartScale {
  static const int _targetIntervals = 6;

  final double minY;
  final double maxY;
  final double interval;

  const FinancialChartScale({
    required this.minY,
    required this.maxY,
    required this.interval,
  });

  factory FinancialChartScale.fromValues(Iterable<double> values) {
    var minimum = 0.0;
    var maximum = 0.0;

    for (final value in values) {
      minimum = min(minimum, value);
      maximum = max(maximum, value);
    }

    if (minimum == maximum) {
      maximum = minimum == 0 ? 1 : maximum + maximum.abs();
    }

    final interval = max(
      1.0,
      _niceInterval((maximum - minimum) / _targetIntervals),
    );
    final minY = (minimum / interval).floor() * interval;
    var maxY = (maximum / interval).ceil() * interval;

    if (minY == maxY) {
      maxY += interval;
    }

    return FinancialChartScale(
      minY: minY,
      maxY: maxY,
      interval: interval,
    );
  }

  static double _niceInterval(double value) {
    final magnitude = pow(10, (log(value) / ln10).floor()).toDouble();
    final normalized = value / magnitude;
    final multiplier = switch (normalized) {
      <= 1 => 1.0,
      <= 2 => 2.0,
      <= 2.5 => 2.5,
      <= 5 => 5.0,
      _ => 10.0,
    };

    return multiplier * magnitude;
  }
}
