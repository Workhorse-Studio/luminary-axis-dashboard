part of axis_dashboard;

class TermData extends JSONSerialisable {
  final String termName;
  final int termStartDate;
  final int termEndDate;

  const TermData({
    required this.termEndDate,
    required this.termName,
    required this.termStartDate,
  });

  bool get hasEndDateSet => termEndDate != 0;

  TermData.fromJson(JSON json)
    : termEndDate = json['termEndDate'] as int,
      termStartDate = json['termStartDate'] as int,
      termName = json['termName'] as String;

  @override
  JSON toJson() => {
    'termName': termName,
    'termStartDate': termStartDate,
    'termEndDate': termEndDate,
  };
}
