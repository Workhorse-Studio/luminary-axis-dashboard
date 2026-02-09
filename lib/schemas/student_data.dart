part of axis_dashboard;

class StudentData extends JSONSerialisable {
  final String role;
  final String name;
  final Map<String, int> initialSessionCount;
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

    required this.initialSessionCount,
  });

  StudentData.fromJson(JSON json)
    : role = json['role'] as String,
      studentContactNo = json['studentContactNo'] as String,
      email = json['email'] as String,
      parentName = json['parentName'] as String,
      parentContactNo = json['parentContactNo'] as String,

      initialSessionCount = Map<String, int>.from(
        json['initialSessionCount'] as Map,
      ),
      name = json['name'] as String;

  @override
  JSON toJson() => {
    'role': role,
    'name': name,
    'email': email,
    'studentContactNo': studentContactNo,
    'parentName': parentName,
    'parentContactNo': parentContactNo,
    'initialSessionCount': initialSessionCount,
  };
}
