part of axis_dashboard;

enum AttendanceType {
  absent,
  presentPhysical,
  presentOnline,
  presentRecording
  ;

  static AttendanceType fromJson(String val) => switch (val) {
    'absent' => absent,
    'presentPhysical' => presentPhysical,
    'presentOnline' => presentOnline,
    'presentRecording' => presentRecording,
    String _ => throw Exception(
      'Could not parse AttendanceType from expression "$val"',
    ),
  };

  static AttendanceType fromLabel(String val) => switch (val) {
    'Absent' => absent,
    'Present Physical' => presentPhysical,
    'Present Online' => presentOnline,
    'Present Recording' => presentRecording,
    String _ => throw Exception(
      'Could not parse AttendanceType from expression "$val"',
    ),
  };

  bool get isPresent => this != absent;

  @override
  String toString() => name;
}

class ClassData extends JSONSerialisable {
  final String name;
  final List<String> studentIds;
  final Map<String, Map<String, AttendanceType>> attendance;

  const ClassData({
    required this.name,
    required this.studentIds,
    required this.attendance,
  });

  ClassData.fromJson(JSON json)
    : name = json['name'] as String,
      studentIds = (json['students'] as List).cast(),
      attendance = (json['attendance'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as Map).map(
            (k2, v2) => MapEntry(
              k2 as String,
              AttendanceType.fromJson(v2 as String),
            ),
          ),
        ),
      );

  @override
  JSON toJson() => {
    'name': role,
    'students': studentIds,
    'attendance': {
      for (final entry in attendance.entries)
        {
          entry.key: {
            for (final e in entry.value.entries) {e.key: e.value.toString()},
          },
        },
    },
  };
}

extension AttendanceDataUtils on Map<String, Map<String, AttendanceType>> {
  JSON toJson() => {
    for (final e1 in entries)
      e1.key: {
        for (final e2 in e1.value.entries) e2.key: e2.value.toString(),
      },
  };
}
