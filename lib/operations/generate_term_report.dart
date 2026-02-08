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

class TermReportV2 {
  List<List> data = [];
  List<double> progresses = [];
  late (int, int) attendanceDatesIndices;
  final GenericCache<StudentData> studentDataCache = GenericCache(
    (studentId) async => StudentData.fromJson(
      (await firestore.collection('users').doc(studentId).get()).data()!,
    ),
  );
  late ClassData classData;
  Future<List<List>> generateTermReport(String classId) async {
    // 12/01: {<id>: true | false}
    // final Map<String, Map<String, String>> attendance = {};
    final Map<String, List<String?>> attendance = {};
    classData = ClassData.fromJson(
      (await firestore.collection('classes').doc(classId).get()).data()!,
    );
    final List<String> dateStrings = [];
    for (final dateKey in classData.attendance.keys) {
      final String dateString = dateKey
          .substring(0, dateKey.length - 5)
          .replaceAll('-', '/');
      dateStrings.add(dateString);
      for (final studentId in classData.studentIds) {
        String? attendanceRecord = null;
        if (classData.attendance[dateKey]!.containsKey(studentId)) {
          attendanceRecord = 'X';
          if (classData.attendance[dateKey]![studentId]!.isPresent) {
            attendanceRecord = dateString;
          }
        }
        if (attendance.containsKey(studentId)) {
          attendance[studentId]!.add(attendanceRecord);
        } else {
          attendance[studentId] = [attendanceRecord];
        }
      }
    }

    data = [
      [
        'Name',
        'Level',
        List<String>.generate(dateStrings.length, (_) => 'Date'),
        'Initial Count',
        'Final Count',
      ],
    ];

    attendanceDatesIndices = (2, classData.attendance.keys.length + 1);

    for (final studentId in classData.studentIds) {
      final studentData = (await studentDataCache.get(studentId));
      data.add([
        studentData.name,
        classData.name.split(' ').first,
        ...attendance[studentId]!,
        studentData.initialSessionCount[classId]!,
        studentData.initialSessionCount[classId]! -
            attendance[studentId]!
                .where(
                  (attendanceType) =>
                      attendanceType != null && attendanceType != 'X',
                )
                .length,
      ]);
      progresses.add(
        1 -
            ((studentData.initialSessionCount[classId]! -
                    attendance[studentId]!
                        .where(
                          (attendanceType) =>
                              attendanceType != null && attendanceType != 'X',
                        )
                        .length) /
                studentData.initialSessionCount[classId]!),
      );
    }

    return data;
  }
}
