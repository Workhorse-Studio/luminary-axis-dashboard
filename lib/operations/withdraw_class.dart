part of axis_dashboard;

Future<void> withdrawStudentFromClass({
  required String studentId,
  required String classId,
}) async {
  await firestore.collection('users').doc(studentId).update({
    'withdrawn.$classId': true,
  });
}
