part of axis_dashboard;

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<StatefulWidget> createState() => TeachersPageState();
}

class TeachersPageState extends State<TeachersPage> {
  bool hasLoaded = false;
  late List<TermData> termsData;
  late List<QueryDocumentSnapshot<JSON>> teachersData;
  final GenericCache<DocumentSnapshot<JSON>> studentCache = GenericCache(
    (studentId) async =>
        await firestore.collection('users').doc(studentId).get(),
  );
  final GenericCache<DocumentSnapshot<JSON>> classesCache = GenericCache(
    (classId) async => await firestore.collection('classes').doc(classId).get(),
  );
  late GlobalState globalState;

  late int currentTermIndex;

  Future<void> loadData() async {
    if (hasLoaded) return;
    globalState = GlobalState.fromJson(
      (await firestore.collection('global').doc('state').get()).data()!,
    );
    teachersData =
        (await (firestore
                    .collection('users')
                    .where(
                      'role',
                      whereIn: const ['teacher', 'admin'],
                    ))
                .get())
            .docs;
    termsData = globalState.terms;
    currentTermIndex = monthKeyToTermIndex(
      globalState,
      DateTime.now().toTimestampStringShort(),
    );
    hasLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        globalState = GlobalState.fromJson(
          (await firestore.collection('global').doc('state').get()).data()!,
        );
        await studentAttendanceStore.ensureInit(
          classesCache: classesCache,
          studentCache: studentCache,
          globalState: globalState,
        );
        await loadData();
        return 1;
      }(),
      builder: (context, _) {
        final List<(String, int)> termEntries = [];
        for (int i = 0; i < termsData.length; i++) {
          termEntries.add((termsData[i].termName, i));
        }
        return Navbar(
          pageTitle: 'Teachers',
          actions: [
            AxisDropdownButton(
              width: 140,
              entries: termEntries,
              onSelected: (newData) => setState(() {
                if (newData != null) currentTermIndex = newData;
              }),
            ),
          ],
          body: (context) => Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    if (currentTermIndex >=
                        studentAttendanceStore.sessionsPerTerm.length)
                      Text(
                        'No term reports to show for this term.',
                        style: body2,
                      ),
                    if (currentTermIndex <
                        studentAttendanceStore.sessionsPerTerm.length)
                      for (final tDoc in teachersData) ...[
                        FutureBuilderTemplate(
                          future: () async {
                            await studentAttendanceStore.ensureInit(
                              classesCache: classesCache,
                              studentCache: studentCache,
                              globalState: globalState,
                            );
                            return (
                              (() {
                                int total = 0;
                                final teacherDataJson = tDoc.data();
                                final teacherClasses = TeacherData.fromJson(teacherDataJson).classIds;
                                
                                if (teacherDataJson['priorSessionCount'] != null) {
                                  total += (teacherDataJson['priorSessionCount'] as num).toInt();
                                }
                                
                                for (final termData in studentAttendanceStore.sessionsPerTerm) {
                                  for (final clEntry in termData.entries) {
                                    if (teacherClasses.contains(clEntry.key)) {
                                      for (final val in clEntry.value.values) { total += (val as num).toInt(); }
                                    }
                                  }
                                }
                                return total;
                              })(),
                              TermReportWidget(
                                teacherId: tDoc.id,
                                termIndex: currentTermIndex,
                              ),
                              TeacherData.fromJson(tDoc.data()).classIds.length,
                            );
                          }(),
                          builder: (context, snapshot) => AxisCard(
                            header: TeacherData.fromJson(tDoc.data()).name,
                            width: 600,
                            height: 320,
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Sessions (Cumulative): ${snapshot.data!.$1}",
                                    style: heading3,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "No. of classes taught: ${snapshot.data!.$3}",
                                    style: heading3,
                                  ),
                                  const SizedBox(height: 30),
                                  AxisButton.text(
                                    label: 'Show Term Report',
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (_) => Center(
                                          child: SizedBox(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.8,
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.8,
                                            child: Material(
                                              color: AxisColors.blackPurple50,
                                              child: snapshot.data!.$2,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
