part of axis_dashboard;

class GlobalState extends JSONSerialisable {
  final int currentTermNum, currentTermStartDate, currentTermEndDate;

  const GlobalState({
    required this.currentTermNum,
    required this.currentTermStartDate,
    required this.currentTermEndDate,
  });

  GlobalState.fromJson(JSON json)
    : currentTermNum = json['currentTermNum'] as int,
      currentTermStartDate = json['currentTermStartDate'] as int,
      currentTermEndDate = json['currentTermEndDate'] as int;

  bool get hasEndDateSet => currentTermEndDate != 0;

  @override
  JSON toJson() => {
    'currentTermNum': currentTermNum,
    'currentTermStartDate': currentTermStartDate,
    'currentTermEndDate': currentTermEndDate,
  };
}
