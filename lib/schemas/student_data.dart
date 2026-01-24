part of axis_dashboard;

class StudentData extends JSONSerialisable {
  final String role;
  final String name;
  final Map<String, int> initialSessionCount;

  const StudentData({
    required this.role,
    required this.name,
    required this.initialSessionCount,
  });

  StudentData.fromJson(JSON json)
    : role = json['role'] as String,
      initialSessionCount = Map<String, int>.from(
        json['initialSessionCount'] as Map,
      ),
      name = json['name'] as String;

  @override
  JSON toJson() => {
    'role': role,
    'name': name,
    'initialSessionCount': initialSessionCount,
  };
}
