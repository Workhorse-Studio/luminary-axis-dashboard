part of axis_dashboard;

class TermAllocation extends JSONSerialisable {
  /// Maps a class ID to the student-allocation mappings for that class in the term.
  final Map<String, Map<String, int>> sessions;

  TermAllocation({
    required this.sessions,
  });

  TermAllocation.fromJson(JSON json)
    : sessions = Map<String, dynamic>.from(
        json,
      ).map((k, v) => MapEntry(k, Map<String, int>.from(v)));

  @override
  JSON toJson() => sessions;
}
