part of axis_dashboard;

class TermReport {
  List<List> data = [];
  List<double> progresses = [];

  late ClassData classData;
  Future<List<List>> generateTermReport(String classId) async {
    final Map<String, List<bool>> attendance = {};
    classData = ClassData.fromJson(
      (await firestore.collection('classes').doc(classId).get()).data()!,
    );
    final List<String> dates = classData.attendance.keys.toList();
    final Map<String, StudentData> studentsData = {};
    for (final studentId in classData.studentIds) {
      attendance[studentId] = List<bool>.generate(dates.length, (_) => false);
      studentsData[studentId] = StudentData.fromJson(
        (await firestore.collection('users').doc(studentId).get()).data()!,
      );
    }
    for (int i = 0; i < dates.length; i++) {
      for (final presentId in classData.attendance[dates[i]]!) {
        attendance[presentId]![i] = true;
      }
    }
    data = [
      [
        'Name',
        'Level',
        ...classData.attendance.keys,
        'Initial Count',
        'Final Count',
      ],
    ];

    for (final studentId in classData.studentIds) {
      data.add([
        studentsData[studentId]!.name,
        classData.name.split(' ').first,
        ...attendance[studentId]!,
        studentsData[studentId]!.initialSessionCount[classId]!,
        studentsData[studentId]!.initialSessionCount[classId]! -
            attendance[studentId]!.where((present) => present).length,
      ]);
      progresses.add(
        1 -
            ((studentsData[studentId]!.initialSessionCount[classId]! -
                    attendance[studentId]!.where((present) => present).length) /
                studentsData[studentId]!.initialSessionCount[classId]!),
      );
    }

    return data;
  }
}
