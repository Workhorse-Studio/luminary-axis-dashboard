part of axis_dashboard;

class OnboardingStudentData extends JSONSerialisable {
  final String studentName;
  final String studentContactNo;
  final String parentName;
  final String parentContactNo;
  final Map<String, String> classIdToTeacherId;
  final String email;

  const OnboardingStudentData({
    required this.studentContactNo,
    required this.studentName,
    required this.parentContactNo,
    required this.parentName,
    required this.email,
    required this.classIdToTeacherId,
  });

  OnboardingStudentData.fromJson(JSON json)
    : studentContactNo = json['studentContactNo'] as String,
      studentName = json['studentName'] as String,
      parentName = json['parentName'] as String,
      email = json['email'] as String,
      parentContactNo = json['parentContactNo'] as String,
      classIdToTeacherId = (json['classIdToTeacherId'] as Map).map(
        (k, v) => MapEntry(k as String, v as String),
      );

  @override
  JSON toJson() => {
    'studentName': studentName,
    'studentContactNo': studentContactNo,
    'parentName': parentName,
    'email': email,
    'parentContactNo': parentContactNo,
    'classIdToTeacherId': classIdToTeacherId,
  };
}
