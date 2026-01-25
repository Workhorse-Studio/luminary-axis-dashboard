part of axis_dashboard;

class ResetTermReportsOperation {
  List<QueryDocumentSnapshot<JSON>> classes = [];

  Future<void> archiveAllClassAttendanceSheets(String termName) async {
    classes.isEmpty
        ? classes = (await firestore.collection('classes').get()).docs
        : null;
    for (final cl in classes) {
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
    classes.isEmpty
        ? classes = (await firestore.collection('classes').get()).docs
        : null;
    final batch = firestore.batch();
    for (final cl in classes) {
      batch.update(cl.reference, {'attendance': {}});
    }
    await batch.commit();
  }
}
