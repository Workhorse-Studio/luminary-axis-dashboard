part of axis_dashboard;

class ClassTemplate extends JSONSerialisable {
  final String className;

  const ClassTemplate({required this.className});

  ClassTemplate.fromJson(JSON json) : className = json['className'] as String;

  @override
  JSON toJson() => {
    'className': className,
  };
}
