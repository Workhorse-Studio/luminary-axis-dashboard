part of axis_dashboard;

class TeacherData extends JSONSerialisable {
  final String role;
  final List<String> classIds;
  final String name;

  /// Maps a term's index to the invoice ID of the student for that term
  final Map<int, String?> invoiceIds;

  const TeacherData({
    required this.name,
    required this.role,
    required this.classIds,
    required this.invoiceIds,
  });

  TeacherData.fromJson(JSON json)
    : name = json['name'] as String,
      role = json['role'] as String,
      invoiceIds = (json['invoiceIds'] as Map).cast(),
      classIds = (json['classes'] as List).cast();

  @override
  JSON toJson() => {
    'name': name,
    'role': role,
    'invoiceIds': invoiceIds,
    'classes': classIds,
  };
}

class TeacherPaymentInfo extends JSONSerialisable {
  final Map<String, int> sessionsPerClass;
  final bool paid;

  const TeacherPaymentInfo({
    required this.sessionsPerClass,
    required this.paid,
  });

  TeacherPaymentInfo.fromJson(JSON json)
    : sessionsPerClass = Map<String, int>.from(
        json['sessionsPerClass'] as Map,
      ),
      paid = json['paid'] as bool;

  @override
  JSON toJson() => {
    'paid': paid,
    'sessionsPerClass': sessionsPerClass,
  };
}
