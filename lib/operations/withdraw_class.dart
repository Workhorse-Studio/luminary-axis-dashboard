part of axis_dashboard;

Future<void> withdrawStudentFromClass({
  required String studentId,
  required String classId,
}) async {
  await runArmTrackedAction<void>(
    feature: 'class_roster',
    operation: 'withdraw_student_from_class',
    severity: ArmSeverity.moderate,
    category: 'data_integrity',
    tags: <String, dynamic>{
      'studentId': studentId,
      'classId': classId,
    },
    recoverySnapshotBuilder: () => <String, dynamic>{
      'studentId': studentId,
      'classId': classId,
      'withdrawn': true,
    },
    action: () async {
      await firestore.collection('users').doc(studentId).update({
        'withdrawn.$classId': true,
      });
    },
  );
}
