part of axis_dashboard;

Future<void> registerStudentForClass({
  required String studentId,
  required String classId,
  required int initialSessionsCount,
}) async {
  await firestore.collection('users').doc(studentId).update({
    'initialSessionCount.$classId': initialSessionsCount,
  });
  final clData = ClassData.fromJson(
    (await firestore.collection('classes').doc(classId).get()).data()!,
  );
  await firestore.collection('classes').doc(classId).update({
    'students': clData.studentIds..add(studentId),
  });
}
