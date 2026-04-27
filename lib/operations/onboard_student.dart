part of axis_dashboard;

Future<String> onboardStudent(OnboardingStudentData obData) async {
  final existingQuery = await firestore
      .collection('users')
      .where('email', isEqualTo: obData.email)
      .where('role', isEqualTo: 'student')
      .get();
  if (existingQuery.docs.isNotEmpty) {
    return existingQuery.docs.first.id;
  }

  final gs = GlobalState.fromJson(
    (await firestore.collection('global').doc('state').get()).data()!,
  );

  final int numTerms = gs.terms.length;

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
    withdrawn: {},
  );
  return (await firestore.collection('users').add(data.toJson())).id;
}
