part of axis_dashboard;

Future<void> withdrawStudentFromClass({
  required String studentId,
  required String classId,
}) async {
  final stData = StudentData.fromJson(
    (await firestore.collection('users').doc(studentId).get()).data()!,
  );

  await firestore.collection('users').doc(studentId).update({
    'initialSessionCount': stData.initialSessionCount..remove(classId),
  });

  final clData = ClassData.fromJson(
    (await firestore.collection('classes').doc(classId).get()).data()!,
  );
  await firestore.collection('classes').doc(classId).update({
    'students': clData.studentIds..remove(studentId),
  });
}
