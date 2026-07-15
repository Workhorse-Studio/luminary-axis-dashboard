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

Future<void> upsertCurrentTermAllocation({
  required String classId,
  required String studentId,
  required int sessionCount,
}) async {
  final gs = GlobalState.fromJson(
    (await firestore.collection('global').doc('state').get()).data()!,
  );
  await firestore
      .collection('global')
      .doc('state')
      .collection('allocations')
      .doc(gs.terms[gs.currentTermNum].termName)
      .set({
        classId: {studentId: sessionCount},
      }, SetOptions(merge: true));
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

Future<
  ({
    bool ok,
    JSON? body,
    String? armCaseId,
    int statusCode,
    String rawBody,
  })
>
makeRequest({
  String url = 'https://axis-server-850501828016.asia-southeast1.run.app/api/',
  String method = 'POST',
  required JSAny body,
  Map<String, String> headers = const {
    'Content-Type': 'application/json',
  },
}) async {
  try {
    armClient.addBreadcrumb(
      'HTTP $method $url started',
      category: 'network',
      data: <String, dynamic>{'url': url, 'method': method},
    );
    final res = await web.window
        .fetch(
          url.toJS,
          web.RequestInit(
            method: method,
            body: body,
            headers: headers.jsify() as web.Headers,
            credentials: 'omit',
          ),
        )
        .toDart;

    final jsonBodyStr = (await res.text().toDart).toDart;
    JSON? parsedBody;
    final armCaseId = res.headers.get('x-arm-case-id');
    if (jsonBodyStr.trim().isNotEmpty) {
      parsedBody = jsonDecode(jsonBodyStr) as JSON;
    }
    armClient.addBreadcrumb(
      'HTTP $method $url completed',
      category: 'network',
      data: <String, dynamic>{
        'ok': res.ok,
        'statusCode': res.status,
        if (armCaseId case final String caseId?) 'armCaseId': caseId,
      },
    );
    return (
      ok: res.ok,
      body: parsedBody,
      armCaseId: armCaseId,
      statusCode: res.status,
      rawBody: jsonBodyStr,
    );
  } catch (e, st) {
    print('makeRequest error: $e');
    armClient.addBreadcrumb(
      'HTTP $method $url threw',
      level: 'error',
      category: 'network',
    );
    Error.throwWithStackTrace(e, st);
  }
}

Never throwArmResponseFailure({
  required int statusCode,
  JSON? body,
  String rawBody = '',
  String? armCaseId,
}) {
  if (armCaseId != null && armCaseId.isNotEmpty) {
    throw ArmLinkedServerFailure(
      caseId: armCaseId,
      statusCode: statusCode,
      body: body,
      rawBody: rawBody,
    );
  }
  throw buildArmResponseFailure(
    statusCode: statusCode,
    body: body,
    rawBody: rawBody,
  );
}

Object buildArmResponseFailure({
  required int statusCode,
  JSON? body,
  String rawBody = '',
}) {
  if (body != null) {
    if (body['exception'] case final Object exception?) {
      return exception;
    }
    if (body['error'] case final Object error?) {
      return error;
    }
    return <String, Object?>{
      'statusCode': statusCode,
      'body': body,
    };
  }

  final trimmedBody = rawBody.trim();
  if (trimmedBody.isNotEmpty) {
    final parsedBody = tryDecodeJsonObject(trimmedBody);
    if (parsedBody != null) {
      return buildArmResponseFailure(statusCode: statusCode, body: parsedBody);
    }
    return trimmedBody;
  }

  return <String, Object?>{'statusCode': statusCode};
}

JSON? tryDecodeJsonObject(String rawBody) {
  try {
    final decoded = jsonDecode(rawBody);
    if (decoded is Map<String, dynamic>) {
      return decoded.cast<String, Object?>();
    }
  } catch (_) {}
  return null;
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
  if (shiftMillis == 0) {
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
