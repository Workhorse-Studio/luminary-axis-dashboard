part of axis_dashboard;

class GlobalState extends JSONSerialisable {
  final List<TermData> terms;
  final int currentTermNum;

  const GlobalState({
    required this.terms,
    required this.currentTermNum,
  });

  GlobalState.fromJson(JSON json)
    : currentTermNum = json['currentTermNum'] as int,
      terms = (json['terms'] as List)
          .cast<JSON>()
          .map(
            (m) => TermData.fromJson(m),
          )
          .toList();

  @override
  JSON toJson() => {
    'terms': terms.map((t) => t.toJson()).toList(),
    'currentTermNum': currentTermNum,
  };
}
