part of axis_dashboard;

typedef JSON = Map<String, Object?>;

abstract class JSONSerialisable {
  const JSONSerialisable();

  JSONSerialisable.fromJson(JSON json);

  JSON toJson();
}
