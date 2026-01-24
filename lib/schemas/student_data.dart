part of axis_dashboard;

class StudentData extends JSONSerialisable {
  final String role;
  final String name;

  const StudentData({
    required this.role,
    required this.name,
  });

  StudentData.fromJson(JSON json)
    : role = json['role'] as String,
      name = json['name'] as String;

  @override
  JSON toJson() => {
    'role': role,
    'name': name,
  };
}
