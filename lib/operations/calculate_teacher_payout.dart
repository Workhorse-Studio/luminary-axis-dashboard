part of axis_dashboard;

class TeacherPayout {
  final Map<String, int> classToNumSessionsMap;
  const TeacherPayout({
    required this.classToNumSessionsMap,
  });

  Map<String, ({int qty, double rate})> generateEntriesPerClass() {
    return {};
  }

  static double calculateFinalPayout(int numSessions) {
    return calculateRate(numSessions) * numSessions;
  }

  static double calculateRate(int numSessions) {
    if (numSessions < 100) {
      return 25;
    } else if (100 <= numSessions && numSessions < 350) {
      return 30;
    } else if (350 <= numSessions && numSessions < 500) {
      return 35;
    } else {
      return 38;
    }
  }
}
