part of axis_dashboard;

Future<String> onboardStudent(OnboardingStudentData obData) async {
  final gs = GlobalState.fromJson(
    (await firestore.collection('global').doc('state').get()).data()!,
  );

  final data = StudentData(
    role: 'student',
    name: obData.studentName,
    email: obData.email,
    studentContactNo: obData.studentContactNo,
    parentContactNo: obData.parentContactNo,
    parentName: obData.parentContactNo,
    invoiceIds: [],
  );
  return (await firestore.collection('users').add(data.toJson())).id;
}
