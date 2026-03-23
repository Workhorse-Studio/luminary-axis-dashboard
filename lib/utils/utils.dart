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

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String generateId() => String.fromCharCodes(
  Iterable.generate(
    16,
    (_) => _chars.codeUnitAt(
      _rnd.nextInt(_chars.length),
    ),
  ),
);

int monthKeyToTermIndex(GlobalState gs, String monthKey) {
  final tmp = monthKey.split('-').reversed.toList();
  tmp[1] = tmp[1].padLeft(2, '0');
  tmp[2] = tmp[2].padLeft(2, '0');
  final String reversedMonthKey = tmp.join('-');
  final dt = DateTime.parse(reversedMonthKey);
  int counter = 0;
  for (final term in gs.terms) {
    if (term.termEndDate >= dt.millisecondsSinceEpoch) {
      return counter;
    } else {
      counter += 1;
    }
  }
  return gs.terms.isEmpty
      ? throw Exception('Month key to term index failed')
      : gs.terms.length - 1;
}

bool hasRolesForRoute(Routes route) =>
    route.requiredRoles.isEmpty ||
    route.requiredRoles.contains(role) ||
    route.requiredRoles.contains('admin') && isAdmin;

extension DateUtils on DateTime {
  String toTimestampString([bool pad = true]) =>
      "${day.toString().padLeft(pad ? 2 : 0, '0')}-${month.toString().padLeft(pad ? 2 : 0, '0')}-${year.toString()} ${hour.toString().padLeft(pad ? 2 : 0)}:${minute.toString().padLeft(pad ? 2 : 0, '0')}:${second.toString().padLeft(pad ? 2 : 0)}";
  String toTimestampStringShort([bool pad = true]) =>
      "${day.toString().padLeft(pad ? 2 : 0, '0')}-${month.toString().padLeft(pad ? 2 : 0, '0')}-${year.toString()}";

  bool isSameDayAs(DateTime other) => DateTime(
    year,
    month,
    day,
  ).isAtSameMomentAs(DateTime(other.year, other.month, other.day));
}
