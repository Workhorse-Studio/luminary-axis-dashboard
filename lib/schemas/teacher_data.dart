part of axis_dashboard;

class TeacherData extends JSONSerialisable {
  final String role;
  final List<String> classIds;
  final String name;
  final String email;
  final String agencyName;
  final String agencyContact;
  final String agencyEmail;
  final String agencyAddress;
  final List<String> offeredClassTemplates;

  /// Maps a month's ID to the invoice ID of the teacher for that term
  final Map<String, String> invoiceIds;

  const TeacherData({
    required this.name,
    required this.role,
    required this.classIds,
    required this.email,
    this.agencyName = '',
    this.agencyContact = '',
    this.agencyEmail = '',
    this.agencyAddress = '',
    required this.invoiceIds,
    required this.offeredClassTemplates,
  });

  TeacherData.fromJson(JSON json)
    : name = json['name'] as String,
      role = json['role'] as String,
      email = json['email'] as String,
      agencyName = (json['agencyName'] as String?) ?? (json['name'] as String),
      agencyContact = (json['agencyContact'] as String?) ?? '',
      agencyEmail =
          (json['agencyEmail'] as String?) ?? (json['email'] as String?) ?? '',
      agencyAddress = (json['agencyAddress'] as String?) ?? '',
      invoiceIds = (json['invoiceIds'] as Map).cast(),
      offeredClassTemplates = (json['offeredClassTemplates'] as List).cast(),
      classIds = (json['classes'] as List).cast();

  @override
  JSON toJson() => {
    'name': name,
    'role': role,
    'invoiceIds': invoiceIds,
    'classes': classIds,
    'email': email,
    'agencyName': agencyName,
    'agencyContact': agencyContact,
    'agencyEmail': agencyEmail,
    'agencyAddress': agencyAddress,
    'offeredClassTemplates': offeredClassTemplates,
  };
}
