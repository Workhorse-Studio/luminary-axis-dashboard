part of axis_dashboard;

class GenericCache<T> {
  final Map<String, T> registry = {};
  final FutureOr<T> Function(String id) operation;
  bool _hasInitAll = false;

  GenericCache(this.operation);

  Future<void> initAll({
    CollectionReference? collection,
    Query? query,
    bool force = false,
  }) async {
    if (_hasInitAll) {
      if (!force) return;
    } else {
      final res = collection != null
          ? (await collection.get()).docs
          : (await query!.get()).docs;
      for (final item in res) {
        registry[item.id] = item as T;
      }
      _hasInitAll = true;
    }
  }

  Future<T> get(String id, {bool bypassCache = false}) async {
    if (bypassCache || !registry.containsKey(id)) {
      return registry[id] = await operation(id);
    } else {
      return registry[id]!;
    }
  }
}

bool hasRolesForRoute(Routes route) =>
    route.requiredRoles.isEmpty ||
    route.requiredRoles.contains(role) ||
    route.requiredRoles.contains('admin') && isAdmin;

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
