part of axis_dashboard;

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<StatefulWidget> createState() => TeachersPageState();
}

class TeachersPageState extends State<TeachersPage> {
  (String, QueryDocumentSnapshot<JSON>)? currentTeacher;
  List<QueryDocumentSnapshot<JSON>> teachersData = [];
  final Map<String, int> teachersSessionsCounts = {};
  bool showTermReport = false;

  final GenericCache<TermReportV2> reportCache = GenericCache((classId) async {
    final TermReportV2 tr = TermReportV2();
    await tr.generateTermReport(classId);
    return tr;
  });

  late final GenericCache<int> teacherNumSessionsCache = GenericCache((
    teacherId,
  ) async {
    int numSessions = TeacherData.fromJson(
      currentTeacher!.$2.data(),
    ).priorSessionCount;
    for (final clId in TeacherData.fromJson(
      currentTeacher!.$2.data(),
    ).classIds) {
      final tr = await reportCache.get(clId);
      for (final row in tr.data.skip(1)) {
        numSessions += row
            .sublist(
              tr.attendanceDatesIndices.$1,
              tr.attendanceDatesIndices.$2 + 1,
            )
            .fold(
              0,
              (a, b) => a + ((b as String?) != '' && b != 'X' ? 1 : 0),
            );
      }
    }
    return numSessions;
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        final query = firestore
            .collection('users')
            .where('role', whereIn: const ['teacher', 'admin']);
        teachersData = (await query.get()).docs;

        return teachersData;
      }(),
      builder: (context, snapshot) {
        return Navbar(
          pageTitle: 'Teachers',
          actions: [
            AxisDropdownButton(
              width: 140,
              initalLabel: TeacherData.fromJson(teachersData.first.data()).name,
              initialSelection: currentTeacher ??= (
                teachersData.first.id,
                teachersData.first,
              ),
              entries: [
                for (final tData in teachersData)
                  (
                    TeacherData.fromJson(tData.data()).name,
                    (tData.id, tData),
                  ),
              ],
              onSelected: (newTData) => setState(() {
                if (newTData != null) currentTeacher = newTData;
              }),
            ),
          ],
          body: (context) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilderTemplate(
                    future: () async {
                      return await teacherNumSessionsCache.get(
                        currentTeacher!.$1,
                      );
                    }(),
                    builder: (context, snapshot) => Text(
                      'Total Sessions: ${snapshot.data}\nTotal Billable Amount: ${calculatePayout(snapshot.data!)}',
                      style: body2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FutureBuilderTemplate(
                    future: () async {
                      return (await firestore
                                  .collection('global')
                                  .doc('state')
                                  .get())
                              .data()!['currentTermNum']
                          as int;
                    }(),
                    builder: (context, snapshot) => Text(
                      '${TeacherData.fromJson(currentTeacher!.$2.data()).name} Term ${snapshot.data} Attendance Sheet',
                      style: body2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Checkbox(
                        value: showTermReport,
                        onChanged: (newVal) => setState(() {
                          if (newVal != null) showTermReport = newVal;
                        }),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Show Term Report',
                        style: body2,
                      ),
                    ],
                  ),
                  if (showTermReport)
                    TermReportWidget(
                      teacherId: currentTeacher!.$1,
                      teacherData: currentTeacher!.$2,
                      reportCache: reportCache,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
