part of axis_dashboard;

class TeacherData extends JSONSerialisable {
  final String role;
  final List<String> classIds;

  const TeacherData({
    required this.role,
    required this.classIds,
  });

  TeacherData.fromJson(JSON json)
    : role = json['role'] as String,
      classIds = (json['classes'] as List).cast();

  @override
  JSON toJson() => {
    'role': role,
    'classes': classIds,
  };
}
