part of axis_dashboard;

Future<void> registerStudentForClass({
  required String studentId,
  required String classId,
  required int initialSessionsCount,
}) async {
  await runArmTrackedAction<void>(
    feature: 'class_roster',
    operation: 'register_student_for_class',
    severity: ArmSeverity.moderate,
    category: 'data_integrity',
    tags: <String, dynamic>{
      'studentId': studentId,
      'classId': classId,
    },
    recoverySnapshotBuilder: () => <String, dynamic>{
      'studentId': studentId,
      'classId': classId,
      'initialSessionsCount': initialSessionsCount,
    },
    action: () async {
      await firestore.collection('users').doc(studentId).update({
        'initialSessionCount.$classId': initialSessionsCount,
      });
      final clData = ClassData.fromJson(
        (await firestore.collection('classes').doc(classId).get()).data()!,
      );
      await firestore.collection('classes').doc(classId).update({
        'students': clData.studentIds..add(studentId),
      });
    },
  );
}
