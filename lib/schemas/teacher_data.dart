part of axis_dashboard;

class TeacherData extends JSONSerialisable {
  final String role;
  final List<String> classIds;
  final String name;
  final int priorSessionCount;

  const TeacherData({
    required this.name,
    required this.role,
    required this.classIds,
    required this.priorSessionCount,
  });

  TeacherData.fromJson(JSON json)
    : name = json['name'] as String,
      role = json['role'] as String,
      priorSessionCount = json['priorSessionCount'] as int,
      classIds = (json['classes'] as List).cast();

  @override
  JSON toJson() => {
    'name': name,
    'role': role,
    'priorSessionCount': priorSessionCount,
    'classes': classIds,
  };
}
