part of axis_dashboard;

class StudentData extends JSONSerialisable {
  final String role;
  final String name;

  /// Maps a term's index to the invoice ID of the student for that term
  final List<String?> invoiceIds;
  final String studentContactNo;
  final String parentName;
  final String parentContactNo;
  final String email;
  final bool withdrawn;

  const StudentData({
    required this.role,
    required this.name,
    required this.email,
    required this.invoiceIds,
    required this.studentContactNo,
    required this.parentContactNo,
    required this.parentName,
    required this.withdrawn,
  });

  StudentData.fromJson(JSON json)
    : role = json['role'] as String,
      studentContactNo = json['studentContactNo'] as String,
      invoiceIds = (json['invoiceIds'] as List).cast(),
      email = json['email'] as String,
      parentName = json['parentName'] as String,
      parentContactNo = json['parentContactNo'] as String,
      withdrawn = json['withdrawn'] as bool,
      name = json['name'] as String;

  @override
  JSON toJson() => {
    'role': role,
    'name': name,
    'email': email,
    'invoiceIds': invoiceIds,
    'studentContactNo': studentContactNo,
    'parentName': parentName,
    'parentContactNo': parentContactNo,
    'widthdrawn': withdrawn,
  };
}
