part of axis_dashboard;

class TeacherData extends JSONSerialisable {
  final String role;
  final List<String> classIds;
  final String name;
  final String email;
  final String agencyName;
  final String addressLine1;
  final String addressLine2;
  final String phoneNum;
  final List<String> offeredClassTemplates;

  /// Maps a month's ID to the invoice ID of the teacher for that term
  final Map<String, String> invoiceIds;

  const TeacherData({
    required this.name,
    required this.role,
    required this.classIds,
    required this.email,
    this.agencyName = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.phoneNum = '',
    required this.invoiceIds,
    required this.offeredClassTemplates,
  });

  TeacherData.fromJson(JSON json)
    : name = json['name'] as String,
      role = json['role'] as String,
      email = json['email'] as String,
      agencyName = (json['agencyName'] as String?) ?? (json['name'] as String),
      addressLine1 = (json['addressLine1'] as String?) ?? '',
      addressLine2 = (json['addressLine2'] as String?) ?? '',
      phoneNum = (json['phoneNum'] as String?) ?? '',
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
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'phoneNum': phoneNum,
    'offeredClassTemplates': offeredClassTemplates,
  };
}
