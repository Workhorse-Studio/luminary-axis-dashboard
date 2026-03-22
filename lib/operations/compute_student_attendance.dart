part of axis_dashboard;

class StudentAttendanceStore {
  /// [ { studentId: { classId: sessionsAttended } } ], with array indexed by term num
  final List<Map<String, Map<String, int>>> sessionsPerTerm = [];
  final List<Map<String, StudentInvoiceData>> invoicesData = [];

  /// [ { studentId: { classId: [ attendedDate / null ] } } ]
  final List<Map<String, Map<String, List<String?>>>> termReports = [];

  final List<Map<String, bool>> hasInvoice = [];
  DateTime? lastRunTs;

  bool _hasInit = false;

  void markStale() => _hasInit = false;

  Future<void> ensureInit({
    required GlobalState globalState,
    required GenericCache<DocumentSnapshot<JSON>> classesCache,
    required GenericCache<DocumentSnapshot<JSON>> studentCache,
  }) async {
    if (_hasInit) {
      return;
    } else {
      await classesCache.initAll(collection: firestore.collection('classes'));
      await studentCache.initAll(
        query: firestore
            .collection('users')
            .where('role', isEqualTo: 'student'),
      );
      await run(
        classesCache: classesCache,
        studentCache: studentCache,
        globalState: globalState,
      );
    }
  }

  Future<void> run({
    required GlobalState globalState,
    required GenericCache<DocumentSnapshot<JSON>> classesCache,
    required GenericCache<DocumentSnapshot<JSON>> studentCache,
    Duration? reuseFrom,
  }) async {
    if (reuseFrom != null &&
        lastRunTs != null &&
        DateTime.now().difference(lastRunTs!) < reuseFrom) {
      return;
    } else {
      sessionsPerTerm.clear();
      termReports.clear();
      invoicesData.clear();
      hasInvoice.clear();
    }

    for (final clEntry in classesCache.registry.entries) {
      for (final attDay in ClassData.fromJson(
        clEntry.value.data()!,
      ).attendance.entries) {
        final int t = monthKeyToTermIndex(globalState, attDay.key);

        for (final e in attDay.value.entries) {
          termReports.ensureLength(
            t,
            map: <String, Map<String, List<String?>>>{},
          );
          termReports[t].ensureKey(e.key, map: <String, List<String?>>{});
          termReports[t][e.key]!.ensureKey(clEntry.key, list: <String?>[]);

          if (e.value.isPresent) {
            sessionsPerTerm.ensureLength(t, map: <String, Map<String, int>>{});
            sessionsPerTerm[t].ensureKey(e.key, map: <String, int>{});

            sessionsPerTerm[t][e.key]![clEntry.key] =
                sessionsPerTerm[t][e.key]!.accessOrElse(
                  clEntry.key,
                  orElse: 0,
                ) +
                1;
            termReports[t][e.key]![clEntry.key]!.add(
              attDay.key.substring(0, attDay.key.length - 5),
            );
          } else {
            termReports[t][e.key]![clEntry.key]!.add('X');
          }
        }
      }
    }
    print(termReports);

    for (final attendanceData in sessionsPerTerm) {
      final Map<String, StudentInvoiceData> currentTermInvoices = {};
      for (final studentEntry in attendanceData.entries) {
        final List<({double amt, String desc, int qty, double rate})> entries =
            [];
        final double rate = studentEntry.value.length >= 3 ? (95 / 2) : 95.00;
        for (final classEntry in studentEntry.value.entries) {
          entries.add((
            desc: ClassData.fromJson(
              (await classesCache.get(classEntry.key)).data()!,
            ).name,
            rate: rate,
            qty: classEntry.value,
            amt: rate * classEntry.value,
          ));
        }
        final sd = StudentData.fromJson(
          (await studentCache.get(studentEntry.key)).data()!,
        );
        final docRef = firestore
            .collection('global')
            .doc('archives')
            .collection('invoices')
            .doc();
        currentTermInvoices[studentEntry.key] = StudentInvoiceData(
          invoiceDateFormatted: DateTime.now().toTimestampStringShort(),
          address: '',
          amtPayable: entries.fold((0), (a, b) => a + b.amt),
          dueDateFormatted: DateTime.now()
              .add(const Duration(days: 7))
              .toTimestampStringShort(),
          entries: entries,
          invoiceStatus: InvoiceStatus.ready,
          invoiceId: docRef.id,
          parentName: sd.parentName,
          studentName: sd.name,
          terms: 'Custom',
        );
        await docRef.set(
          currentTermInvoices[studentEntry.key]!.toJson(),
        );
      }
      invoicesData.add(currentTermInvoices);
    }

    if (!_hasInit) _hasInit = true;
    lastRunTs = DateTime.now();
  }
}

extension ListUtilsMap<T> on List<T> {
  void ensureLength(int l, {required T map}) {
    if (l <= length) {
      for (int i = length - 1; i < l; i++) {
        add(map);
      }
    }
  }
}

extension MapUtilsAny<T> on Map<String, T> {
  T accessOrElse(
    String key, {
    required T orElse,
  }) {
    return containsKey(key) ? this[key]! : this[key] = orElse;
  }
}

extension MapUtilsMap<T> on Map<String, T> {
  void ensureKey(String key, {required T map}) =>
      containsKey(key) ? null : this[key] = map;
}

extension MapUtilsList<T> on Map<String, List<T>> {
  void ensureKey(String key, {required List<T> list}) =>
      containsKey(key) ? null : this[key] = list;
}
