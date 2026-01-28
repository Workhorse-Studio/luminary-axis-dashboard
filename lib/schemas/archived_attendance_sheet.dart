part of axis_dashboard;

class ArchivedAttendanceSheet extends JSONSerialisable {
  final String timestamp;
  final Map<String, Map<String, AttendanceType>> attendance;

  const ArchivedAttendanceSheet({
    required this.timestamp,
    required this.attendance,
  });

  ArchivedAttendanceSheet.fromJson(JSON json)
    : attendance = (json['attendance'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as Map).map(
            (k2, v2) => MapEntry(
              k2 as String,
              AttendanceType.fromJson(v2 as String),
            ),
          ),
        ),
      ),
      timestamp = json['timestamp'] as String;

  @override
  JSON toJson() => {
    'timestamp': timestamp,
    'attendance': attendance,
  };
}
