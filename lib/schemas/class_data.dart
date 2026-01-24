part of axis_dashboard;

class ClassData extends JSONSerialisable {
  final String name;
  final List<String> studentIds;
  final Map<String, List<String>> attendance;

  const ClassData({
    required this.name,
    required this.studentIds,
    required this.attendance,
  });

  ClassData.fromJson(JSON json)
    : name = json['name'] as String,
      studentIds = (json['students'] as List).cast(),
      attendance = (json['attendance'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );

  @override
  JSON toJson() => {
    'name': role,
    'students': studentIds,
    'attendance': attendance,
  };
}
