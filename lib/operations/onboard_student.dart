part of axis_dashboard;

Future<String> onboardStudent(OnboardingStudentData obData) async {
  final int numTerms = GlobalState.fromJson(
    (await firestore.collection('global').doc('state').get()).data()!,
  ).terms.length;
  final data = StudentData(
    role: 'student',
    name: obData.studentName,
    email: obData.email,
    studentContactNo: obData.studentContactNo,
    parentContactNo: obData.parentContactNo,
    parentName: obData.parentContactNo,
    school: obData.school,
    postalCode: obData.postalCode,
    address: obData.address,
    subjectCombi: obData.subjectCombi,
    invoiceIds: List<String?>.generate(numTerms, (_) => null),
    withdrawn: {for (final k in obData.classes) k: false},
  );
  return (await firestore.collection('users').add(data.toJson())).id;
}
