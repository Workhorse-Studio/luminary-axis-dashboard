part of axis_dashboard;

class TermReport {
  List<List> data = [];
  List<double> progresses = [];
  late (int, int) attendanceDatesIndices;

  late ClassData classData;
  Future<List<List>> generateTermReport(String classId) async {
    final Map<String, List<AttendanceType>> attendance = {};
    classData = ClassData.fromJson(
      (await firestore.collection('classes').doc(classId).get()).data()!,
    );
    final List<String> dates = classData.attendance.keys.toList();
    final Map<String, StudentData> studentsData = {};
    for (final studentId in classData.studentIds) {
      attendance[studentId] = List<AttendanceType>.generate(
        dates.length,
        (_) => AttendanceType.absent,
      );
      studentsData[studentId] = StudentData.fromJson(
        (await firestore.collection('users').doc(studentId).get()).data()!,
      );
    }
    for (int i = 0; i < dates.length; i++) {
      for (final entry in classData.attendance[dates[i]]!.entries) {
        attendance[entry.key]![i] = entry.value;
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

    attendanceDatesIndices = (2, classData.attendance.keys.length + 1);

    for (final studentId in classData.studentIds) {
      data.add([
        studentsData[studentId]!.name,
        classData.name.split(' ').first,
        ...attendance[studentId]!,
        studentsData[studentId]!.initialSessionCount[classId]!,
        studentsData[studentId]!.initialSessionCount[classId]! -
            attendance[studentId]!
                .where((attendanceType) => attendanceType.isPresent)
                .length,
      ]);
      progresses.add(
        1 -
            ((studentsData[studentId]!.initialSessionCount[classId]! -
                    attendance[studentId]!
                        .where((attendanceType) => attendanceType.isPresent)
                        .length) /
                studentsData[studentId]!.initialSessionCount[classId]!),
      );
    }

    return data;
  }
}
