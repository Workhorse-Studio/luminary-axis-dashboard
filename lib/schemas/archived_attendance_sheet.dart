part of axis_dashboard;

class ArchivedAttendanceSheet extends JSONSerialisable {
  final String timestamp;
  final Map<String, List<String>> attendance;

  const ArchivedAttendanceSheet({
    required this.timestamp,
    required this.attendance,
  });

  ArchivedAttendanceSheet.fromJson(JSON json)
    : attendance = ((json['attendance'] as Map<String, Object?>)).map(
        (k, v) => MapEntry(k, (v as List).cast<String>()),
      ),
      timestamp = json['timestamp'] as String;

  @override
  JSON toJson() => {
    'timestamp': timestamp,
    'attendance': attendance,
  };
}
