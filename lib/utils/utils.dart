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
    if (_hasInitAll && !force) {
      return;
    }

    final res = collection != null
        ? (await collection.get()).docs
        : (await query!.get()).docs;
    for (final item in res) {
      registry[item.id] = item as T;
    }
    _hasInitAll = true;
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

Future<({bool ok, JSON? body})> makeRequest({
  String url = 'https://axis-server-850501828016.asia-southeast1.run.app/api/',
  String method = 'POST',
  required JSAny body,
  Map<String, String> headers = const {
    'Content-Type': 'application/json',
  },
}) async {
  try {
    final res = await web.window
        .fetch(
          url.toJS,
          web.RequestInit(
            method: 'POST',
            body: body,
            headers: headers.jsify() as web.Headers,
            credentials: 'omit',
          ),
        )
        .toDart;

    final jsonBodyStr = (await res.text().toDart).toDart;
    JSON? parsedBody;
    if (jsonBodyStr.trim().isNotEmpty) {
      parsedBody = jsonDecode(jsonBodyStr) as JSON;
    }
    return (
      ok: res.ok,
      body: parsedBody,
    );
  } catch (e) {
    print('makeRequest error: $e');
    return (ok: false, body: null);
  }
}

String generateId() => String.fromCharCodes(
  Iterable.generate(
    16,
    (_) => _chars.codeUnitAt(
      _rnd.nextInt(_chars.length),
    ),
  ),
);

const String attendanceSessionDelimiter = '__s';

String attendanceBaseDateKey(String attendanceKey) {
  final int i = attendanceKey.indexOf(attendanceSessionDelimiter);
  return i >= 0 ? attendanceKey.substring(0, i) : attendanceKey;
}

DateTime attendanceKeyToDateTime(String attendanceKey) {
  final chunks = attendanceBaseDateKey(attendanceKey).split('-');
  if (chunks.length != 3) {
    throw Exception('Invalid attendance key "$attendanceKey"');
  }
  return DateTime(
    int.parse(chunks[2]),
    int.parse(chunks[1]),
    int.parse(chunks[0]),
  );
}

int attendanceSessionNumber(String attendanceKey) {
  final int i = attendanceKey.indexOf(attendanceSessionDelimiter);
  if (i < 0) return 1;
  return int.tryParse(
        attendanceKey.substring(i + attendanceSessionDelimiter.length),
      ) ??
      1;
}

String attendanceSessionLabel(String attendanceKey) =>
    'S${attendanceSessionNumber(attendanceKey)}';

int compareAttendanceKeys(String a, String b) {
  final int dateCmp = attendanceKeyToDateTime(a).compareTo(
    attendanceKeyToDateTime(b),
  );
  if (dateCmp != 0) {
    return dateCmp;
  }
  return attendanceSessionNumber(a).compareTo(attendanceSessionNumber(b));
}

String attendanceMonthId(String attendanceKey) {
  final dt = attendanceKeyToDateTime(attendanceKey);
  return '${dt.month}-${dt.year}';
}

String buildAttendanceSessionKey({
  required DateTime date,
  required int sessionNumber,
}) {
  return '${date.toTimestampStringShort(false)}$attendanceSessionDelimiter'
      '${sessionNumber.toString().padLeft(3, '0')}';
}

bool attendanceKeyMatchesDate(String attendanceKey, DateTime date) {
  final attDt = attendanceKeyToDateTime(attendanceKey);
  return attDt.year == date.year &&
      attDt.month == date.month &&
      attDt.day == date.day;
}

int nextAttendanceSessionNumberForDate(
  Iterable<String> attendanceKeys,
  DateTime date,
) {
  int maxSession = 0;
  for (final key in attendanceKeys) {
    if (!attendanceKeyMatchesDate(key, date)) continue;
    final int n = attendanceSessionNumber(key);
    if (n > maxSession) {
      maxSession = n;
    }
  }
  return maxSession + 1;
}

int monthKeyToTermIndex(GlobalState gs, String monthKey) {
  final dt = attendanceKeyToDateTime(monthKey);
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

List<TermData> rebuildTermsAfterEndDateChange({
  required List<TermData> terms,
  required int currentTabIndex,
  required int newEndDateMillis,
}) {
  final List<TermData> newData = [
    ...terms.sublist(0, currentTabIndex),
    TermData(
      termEndDate: newEndDateMillis,
      termName: terms[currentTabIndex].termName,
      termStartDate: terms[currentTabIndex].termStartDate,
    ),
  ];
  if (currentTabIndex >= terms.length - 1) {
    return newData;
  }

  final int shiftMillis =
      newEndDateMillis - terms[currentTabIndex + 1].termStartDate + 1000;
  if (shiftMillis <= 0) {
    newData.addAll(terms.sublist(currentTabIndex + 1));
    return newData;
  }

  for (final term in terms.sublist(currentTabIndex + 1)) {
    newData.add(
      TermData(
        termEndDate: term.termEndDate + shiftMillis,
        termName: term.termName,
        termStartDate: term.termStartDate + shiftMillis,
      ),
    );
  }
  return newData;
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

bool isStudentCompletelyWithdrawn(
  String studentId,
  StudentData sd,
  GenericCache<DocumentSnapshot<JSON>> classesCache,
) {
  bool hasAnyClasses = false;
  bool hasActiveClasses = false;
  for (final clEntry in classesCache.registry.entries) {
    final cd = ClassData.fromJson(clEntry.value.data()!);
    if (cd.studentIds.contains(studentId)) {
      hasAnyClasses = true;
      if (sd.withdrawn[clEntry.key] != true) {
        hasActiveClasses = true;
        break;
      }
    }
  }
  return hasAnyClasses && !hasActiveClasses;
}
