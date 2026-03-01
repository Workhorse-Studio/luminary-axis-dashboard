part of axis_dashboard;

class StudentData extends JSONSerialisable {
  final String role;
  final String name;

  /// Indexed by termNum, and each item maps a `classId` to a `sessionsCount`
  final List<Map<String, int>> sessionCounts;
  final String studentContactNo;
  final String parentName;
  final String parentContactNo;
  final String email;

  const StudentData({
    required this.role,
    required this.name,
    required this.email,

    required this.studentContactNo,
    required this.parentContactNo,
    required this.parentName,
    required this.sessionCounts,
  });

  StudentData.fromJson(JSON json)
    : role = json['role'] as String,
      studentContactNo = json['studentContactNo'] as String,
      email = json['email'] as String,
      parentName = json['parentName'] as String,
      parentContactNo = json['parentContactNo'] as String,

      sessionCounts = (json['sessionCounts'] as List)
          .map((e) => Map<String, int>.from(e))
          .toList(),
      name = json['name'] as String;

  @override
  JSON toJson() => {
    'role': role,
    'name': name,
    'email': email,
    'studentContactNo': studentContactNo,
    'parentName': parentName,
    'parentContactNo': parentContactNo,
    'sessionCounts': sessionCounts,
  };
}
