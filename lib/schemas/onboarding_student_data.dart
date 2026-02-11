part of axis_dashboard;

class OnboardingStudentData extends JSONSerialisable {
  final String studentName;
  final String studentContactNo;
  final String parentName;
  final String parentContactNo;
  final String teacherId;
  final String classId;
  final bool hasOnboarded;
  final String email;

  const OnboardingStudentData({
    required this.studentContactNo,
    required this.studentName,
    required this.parentContactNo,
    required this.hasOnboarded,
    required this.parentName,
    required this.teacherId,
    required this.email,
    required this.classId,
  });

  OnboardingStudentData.fromJson(JSON json)
    : studentContactNo = json['studentContactNo'] as String,
      hasOnboarded = json['hasOnboarded'] as bool,
      studentName = json['studentName'] as String,
      parentName = json['parentName'] as String,
      email = json['email'] as String,
      parentContactNo = json['parentContactNo'] as String,
      teacherId = json['teacherId'] as String,
      classId = json['classId'] as String;

  @override
  JSON toJson() => {
    'studentName': studentName,
    'studentContactNo': studentContactNo,
    'parentName': parentName,
    'email': email,
    'hasOnboarded': hasOnboarded,
    'parentContactNo': parentContactNo,
    'teacherId': teacherId,
    'classId': classId,
  };
}
