part of axis_dashboard;

class GlobalState extends JSONSerialisable {
  final List<TermData> terms;

  const GlobalState({
    required this.terms,
  });

  GlobalState.fromJson(JSON json)
    : terms = (json['terms'] as List)
          .cast<JSON>()
          .map(
            (m) => TermData.fromJson(m),
          )
          .toList();

  @override
  JSON toJson() => {
    'terms': terms.map((t) => t.toJson()).toList(),
  };
}
