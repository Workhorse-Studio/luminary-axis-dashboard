part of axis_dashboard;

class ResetTermReportsOperation {
  final GenericCache<QueryDocumentSnapshot<JSON>> classesCache = GenericCache((
    classId,
  ) async {
    return (await firestore
            .collection('classes')
            .where(FieldPath.documentId, isEqualTo: classId)
            .limit(1)
            .get())
        .docs
        .first;
  });

  Future<void> executeInSequence(String termName) async {
    await archiveAllClassAttendanceSheets(termName);
    await rollOverTeacherSessionCounts();
    await resetAllClassAttendanceSheets();
  }

  Future<void> archiveAllClassAttendanceSheets(String termName) async {
    final bool isCacheEmpty = classesCache.registry.isEmpty;
    final classDocs = isCacheEmpty
        ? (await firestore.collection('classes').get()).docs
        : classesCache.registry.values;

    for (final cl in classDocs) {
      if (isCacheEmpty) classesCache.registry[cl.id] = cl;
      await firestore
          .collection('archives')
          .doc('term_reports')
          .collection(cl.id)
          .doc(termName)
          .set(
            ArchivedAttendanceSheet(
              timestamp: DateTime.now().toTimestampString(),
              attendance: ClassData.fromJson(cl.data()).attendance,
            ).toJson(),
          );
    }
  }

  Future<void> resetAllClassAttendanceSheets() async {
    final bool isCacheEmpty = classesCache.registry.isEmpty;
    final classDocs = isCacheEmpty
        ? (await firestore.collection('classes').get()).docs
        : classesCache.registry.values;

    final batch = firestore.batch();
    for (final cl in classDocs) {
      if (isCacheEmpty) classesCache.registry[cl.id] = cl;

      batch.update(cl.reference, {'attendance': {}});
    }

    await batch.commit();
    final shadowDocs =
        (await firestore
                .collection('global')
                .doc('state')
                .collection('nextTermSessionAllocations')
                .get())
            .docs;

    final batchDelete = firestore.batch();
    for (final sd in shadowDocs) {
      batchDelete.delete(sd.reference);
    }
    await batchDelete.commit();
  }

  Future<void> rollOverTeacherSessionCounts() async {
    final teachersDocs =
        (await firestore
                .collection('users')
                .where('role', isEqualTo: 'teacher')
                .get())
            .docs;
    for (final tDoc in teachersDocs) {
      final tData = TeacherData.fromJson(tDoc.data());
      int numSessions = tData.priorSessionCount;
      for (final clId in tData.classIds) {
        numSessions += ClassData.fromJson(
          (await classesCache.get(clId)).data(),
        ).attendance.values.fold(0, (old, curr) => old + curr.length);
      }
      await firestore.collection('users').doc(tDoc.id).update({
        'priorSessionCount': numSessions,
      });
    }
  }
}
