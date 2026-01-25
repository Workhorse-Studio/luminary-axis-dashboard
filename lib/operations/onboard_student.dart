part of axis_dashboard;

Future<String> onboardStudent(StudentData data) async =>
    (await firestore.collection('users').add(data.toJson())).id;
