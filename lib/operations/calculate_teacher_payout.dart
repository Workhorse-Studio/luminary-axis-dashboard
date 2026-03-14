part of axis_dashboard;

class TeacherPayout {
  final Map<String, int> classToNumSessionsMap;
  const TeacherPayout({
  required this.classToNumSessionsMap,
  });

  Map<String, ({int qty, double rate})> generateEntriesPerClass() {
    return {};
  }

  double calculateFinalPayout(int numSessions) {
    if (numSessions < 100) {
      return numSessions * 25;
    } else if (100 <= numSessions && numSessions < 350) {
      return numSessions * 30;
    } else if (350 <= numSessions && numSessions < 500) {
      return numSessions * 35;
    } else {
      return numSessions * 38;
    }
  }
}
