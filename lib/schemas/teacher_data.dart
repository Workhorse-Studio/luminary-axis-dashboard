part of axis_dashboard;

class TeacherData extends JSONSerialisable {
  final String role;
  final List<String> classIds;
  final String name;

  /// Maps a term's index to the invoice ID of the student for that term
  final List<String?> invoiceIds;

  const TeacherData({
    required this.name,
    required this.role,
    required this.classIds,
    required this.invoiceIds,
  });

  TeacherData.fromJson(JSON json)
    : name = json['name'] as String,
      role = json['role'] as String,
      invoiceIds = (json['invoiceIds'] as List).cast(),
      classIds = (json['classes'] as List).cast();

  @override
  JSON toJson() => {
    'name': name,
    'role': role,
    'invoiceIds': invoiceIds,
    'classes': classIds,
  };
}
