part of axis_dashboard;

class OnboardingStudentData extends JSONSerialisable {
  final String studentName;
  final String studentContactNo;
  final String parentName;
  final String parentContactNo;
  final String teacherId;
  final String classId;

  const OnboardingStudentData({
    required this.studentContactNo,
    required this.studentName,
    required this.parentContactNo,
    required this.parentName,
    required this.teacherId,
    required this.classId,
  });

  OnboardingStudentData.fromJson(JSON json)
    : studentContactNo = json['studentContactNo'] as String,
      studentName = json['studentName'] as String,
      parentName = json['parentName'] as String,
      parentContactNo = json['parentContactNo'] as String,
      teacherId = json['teacherId'] as String,
      classId = json['classId'] as String;

  @override
  JSON toJson() => {
    'studentName': studentName,
    'studentContactNo': studentContactNo,
    'parentName': parentName,

    'parentContactNo': parentContactNo,
    'teacherId': teacherId,
    'classId': classId,
  };
}
