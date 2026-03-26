part of axis_dashboard;

class OnboardingStudentData extends JSONSerialisable {
  final String studentName;
  final String studentContactNo;
  final String parentName;
  final String parentContactNo;
  final String email;
  final String address;
  final String postalCode;
  final String school;
  final String subjectCombi;
  final List<String> classes;

  const OnboardingStudentData({
    required this.studentContactNo,
    required this.studentName,
    required this.parentContactNo,
    required this.parentName,
    required this.email,
    required this.address,
    required this.postalCode,
    required this.school,
    required this.subjectCombi,
    required this.classes,
  });

  OnboardingStudentData.fromJson(JSON json)
    : studentContactNo = json['studentContactNo'] as String,
      studentName = json['studentName'] as String,
      parentName = json['parentName'] as String,
      email = json['email'] as String,
      parentContactNo = json['parentContactNo'] as String,
      address = json['address'] as String,
      postalCode = json['postalCode'] as String,
      school = json['school'] as String,
      classes = (json['classes'] as List).cast(),
      subjectCombi = json['subjectCombi'] as String;
  @override
  JSON toJson() => {
    'studentName': studentName,
    'studentContactNo': studentContactNo,
    'parentName': parentName,
    'email': email,
    'parentContactNo': parentContactNo,
    'address': address,
    'school': school,
    'postalCode': postalCode,
    'subjectCombi': subjectCombi,
    'classes': classes,
  };
}
