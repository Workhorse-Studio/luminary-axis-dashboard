part of axis_dashboard;

class StudentAttendanceStore {
  static bool invoicePayloadMatches(
    StudentInvoiceData a,
    StudentInvoiceData b,
  ) {
    if (a.amtPayable != b.amtPayable) return false;
    if (a.entries.length != b.entries.length) return false;
    for (int i = 0; i < a.entries.length; i++) {
      final x = a.entries[i], y = b.entries[i];
      if (x.desc != y.desc ||
          x.qty != y.qty ||
          x.rate != y.rate ||
          x.amt != y.amt) {
        return false;
      }
    }
    return a.studentName == b.studentName &&
        a.parentName == b.parentName &&
        a.terms == b.terms;
  }

  /// [ { studentId: { classId: sessionsAttended } } ], with array indexed by term num
  final List<Map<String, Map<String, int>>> sessionsPerTerm = [];

  /// [ { studentId: InvoiceData } ], with array indexed by term num
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

  Future<int> run({
    required GlobalState globalState,
    required GenericCache<DocumentSnapshot<JSON>> classesCache,
    required GenericCache<DocumentSnapshot<JSON>> studentCache,
    Duration? reuseFrom,
  }) async {
    if (reuseFrom != null &&
        lastRunTs != null &&
        DateTime.now().difference(lastRunTs!) < reuseFrom) {
      return 0;
    } else {
      sessionsPerTerm.clear();
      termReports.clear();
      invoicesData.clear();
      hasInvoice.clear();
      for (int i = 0; i < globalState.terms.length; i++) {
        sessionsPerTerm.add(<String, Map<String, int>>{});
        termReports.add(<String, Map<String, List<String?>>>{});
        hasInvoice.add(<String, bool>{});
      }
    }

    int numUpdated = 0;

    final allocationsByTerm = <String, TermAllocation>{};
    for (final term in globalState.terms) {
      final doc = await firestore
          .collection('global')
          .doc('state')
          .collection('allocations')
          .doc(term.termName)
          .get();
      if (doc.exists && doc.data() != null) {
        allocationsByTerm[term.termName] = TermAllocation.fromJson(doc.data()!);
      } else {
        allocationsByTerm[term.termName] = TermAllocation(sessions: {});
      }
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
    for (int t = 0; t < sessionsPerTerm.length; t++) {
      final termReportData = termReports[t];
      final Map<String, StudentInvoiceData> currentTermInvoices = {};
      for (final studentEntry in studentCache.registry.entries) {
        final studentId = studentEntry.key;
        final sd = StudentData.fromJson(studentEntry.value.data()!);

        final termName = globalState.terms[t].termName;
        final termAllocations = allocationsByTerm[termName]!;

        final Map<String, int> relevantClasses = {};
        for (final clEntry in classesCache.registry.entries) {
          final classId = clEntry.key;
          final classData = ClassData.fromJson(clEntry.value.data()!);

          int sessionCount =
              termAllocations.sessions[classId]?[studentId] ?? -1;
          if (sessionCount == -1) {
            final studentReport = termReportData[studentId];
            if (studentReport != null && studentReport.containsKey(classId)) {
              sessionCount = studentReport[classId]!
                  .where((x) => x != 'X')
                  .length;
            } else {
              sessionCount = 0;
            }
          }

          if (sessionCount > 0 ||
              (classData.studentIds.contains(studentId) &&
                  sd.withdrawn[classId] != true)) {
            relevantClasses[classId] = sessionCount;
          }
        }

        if (relevantClasses.isEmpty &&
            (sd.invoiceIds.length <= t || sd.invoiceIds[t] == null)) {
          continue;
        }

        DocumentSnapshot<JSON>? existingInvoice;
        if (sd.invoiceIds.length > t && sd.invoiceIds[t] != null) {
          existingInvoice = await firestore
              .collection('global')
              .doc('archives')
              .collection('invoices')
              .doc(sd.invoiceIds[t])
              .get();
        }
        final List<({double amt, String desc, int qty, double rate})> entries =
            [];

        int classIndex = 0;
        for (final classEntry in relevantClasses.entries) {
          final classId = classEntry.key;
          final sessionCount = classEntry.value;

          final double rate = classIndex < 2 ? 95.00 : (95.00 / 2);
          classIndex++;

          entries.add((
            desc: ClassData.fromJson(
              (await classesCache.get(classId)).data()!,
            ).name,
            rate: rate,
            qty: sessionCount,
            amt: rate * sessionCount,
          ));
        }

        /// Save or Update
        final docRef = firestore
            .collection('global')
            .doc('archives')
            .collection('invoices')
            .doc();
        final candidate = StudentInvoiceData(
          invoiceDateFormatted: DateTime.now().toTimestampStringShort(),
          address: '',
          amtPayable: entries.fold((0), (a, b) => a + b.amt),
          dueDateFormatted: DateTime.now()
              .add(const Duration(days: 7))
              .toTimestampStringShort(),
          entries: entries,
          invoiceStatus: InvoiceStatus.pendingPayment,
          invoiceId: docRef.id,
          parentName: sd.parentName,
          studentName: sd.name,
          terms: 'Custom',
        );

        bool refsUpdated = false;
        if (existingInvoice != null) {
          if (invoicePayloadMatches(
            StudentInvoiceData.fromJson(existingInvoice.data()!),
            candidate,
          )) {
            // Do nothing
            currentTermInvoices[studentEntry.key] = StudentInvoiceData.fromJson(
              existingInvoice.data()!,
            );
            continue;
          } else {
            // Create new invoice (done above) and link student's data to that
            await firestore.collection('users').doc(studentEntry.key).update({
              'invoiceIds': sd.invoiceIds..[t] = docRef.id,
            });
            refsUpdated = true;
          }
        }

        numUpdated++;

        currentTermInvoices[studentEntry.key] = candidate;
        await docRef.set(
          currentTermInvoices[studentEntry.key]!.toJson(),
        );
        if (!refsUpdated) {
          await firestore.collection('users').doc(studentEntry.key).update({
            'invoiceIds': sd.invoiceIds
              ..ensureLength(t, map: null)
              ..[t] = docRef.id,
          });
        }
        await studentCache.get(studentEntry.key, bypassCache: true);
      }
      invoicesData.add(currentTermInvoices);
    }

    if (!_hasInit) _hasInit = true;
    lastRunTs = DateTime.now();
    return numUpdated;
  }
}

extension ListUtilsMap<T> on List<T> {
  void ensureLength(int l, {required T map}) {
    while (length <= l) {
      add(map);
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
