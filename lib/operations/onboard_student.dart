part of axis_dashboard;

Future<String> onboardStudent(OnboardingStudentData obData) async {
  final data = StudentData(
    role: 'student',
    name: obData.studentName,
    email: obData.email,
    studentContactNo: obData.studentContactNo,
    parentContactNo: obData.parentContactNo,
    parentName: obData.parentContactNo,
    invoiceIds: [],
    withdrawn: {for (final k in obData.classIdToTeacherId.keys) k: true},
  );
  return (await firestore.collection('users').add(data.toJson())).id;
}
