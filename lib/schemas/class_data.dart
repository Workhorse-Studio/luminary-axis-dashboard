part of axis_dashboard;

class ClassData extends JSONSerialisable {
  final String name;
  final List<String> studentIds;

  const ClassData({
    required this.name,
    required this.studentIds,
  });

  ClassData.fromJson(JSON json)
    : name = json['name'] as String,
      studentIds = (json['students'] as List).cast();

  @override
  JSON toJson() => {
    'name': role,
    'students': studentIds,
  };
}
