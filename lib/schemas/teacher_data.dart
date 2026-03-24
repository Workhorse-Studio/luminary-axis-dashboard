part of axis_dashboard;

class TeacherData extends JSONSerialisable {
  final String role;
  final List<String> classIds;
  final String name;
  final String email;

  /// Maps a month's ID to the invoice ID of the teacher for that term
  final Map<String, String> invoiceIds;

  const TeacherData({
    required this.name,
    required this.role,
    required this.classIds,
    required this.email,
    required this.invoiceIds,
  });

  TeacherData.fromJson(JSON json)
    : name = json['name'] as String,
      role = json['role'] as String,
      email = json['email'] as String,
      invoiceIds = (json['invoiceIds'] as Map).cast(),
      classIds = (json['classes'] as List).cast();

  @override
  JSON toJson() => {
    'name': name,
    'role': role,
    'invoiceIds': invoiceIds,
    'classes': classIds,
    'email': email,
  };
}
