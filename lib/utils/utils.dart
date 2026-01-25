part of axis_dashboard;

class GenericCache<T> {
  final Map<String, T> registry = {};
  final FutureOr<T> Function(String id) operation;

  GenericCache(this.operation);

  Future<T> get(String id) async {
    if (registry.containsKey(id)) {
      return registry[id]!;
    } else {
      return registry[id] = await operation(id);
    }
  }
}

extension DateUtils on DateTime {
  String toTimestampString() =>
      "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year.toString()} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}";
  String toTimestampStringShort() =>
      "${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year.toString()}";

  bool isSameDayAs(DateTime other) => DateTime(
    year,
    month,
    day,
  ).isAtSameMomentAs(DateTime(other.year, other.month, other.day));
}
