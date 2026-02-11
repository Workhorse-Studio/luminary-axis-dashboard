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

  late int currentTermIndex;

  // final Map<String, int> teachersSessionsCounts = {};
  bool showTermReport = false;

  final GenericCache<TermReportV2> reportCache = GenericCache((key) async {
    final List<String> args = key.split(';');
    final TermReportV2 tr = TermReportV2();
    await tr.generateTermReport(
      args[0],
      int.parse(args[1]),
      int.parse(args[2]),
    );
    return tr;
  });

  Future<void> loadData() async {
    if (hasLoaded) return;
    teachersData =
        (await (firestore
                    .collection('users')
                    .where(
                      'role',
                      whereIn: const ['teacher', 'admin'],
                    ))
                .get())
            .docs;
    termsData = GlobalState.fromJson(
      (await firestore.collection('global').doc('state').get()).data()!,
    ).terms;
    currentTermIndex = termsData.length - 1;
    hasLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        await loadData();
        return 1;
      }(),
      builder: (context, _) {
        final List<(String, int)> termEntries = [];
        for (int i = 0; i < termsData.length; i++) {
          termEntries.add((termsData[i].termName, i));
        }
        return Navbar(
          pageTitle: 'Billing',
          actions: [
            AxisDropdownButton(
              width: 140,
              initalLabel: termsData[currentTermIndex].termName,
              initialSelection: currentTermIndex,
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
                    for (final tDoc in teachersData) ...[
                      FutureBuilderTemplate(
                        future: () async {
                          int numSessions = 0;
                          final tData = TeacherData.fromJson(tDoc.data());
                          final List<TermReportV2> reports = [];
                          for (final clId in tData.classIds) {
                            final report = await reportCache.get(
                              '$clId;${termsData[currentTermIndex].termStartDate};${termsData[currentTermIndex].termEndDate}',
                            );
                            reports.add(report);
                            for (final row in report.data.skip(1)) {
                              numSessions += row
                                  .where(
                                    (cell) =>
                                        (cell is String) &&
                                        cell != '' &&
                                        cell != 'X',
                                  )
                                  .length;
                            }
                          }
                          final double billableAmt = calculatePayout(
                            numSessions,
                          );
                          return (numSessions, billableAmt, reports);
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
                                  "Sessions in period: ${snapshot.data!.$1}",
                                  style: heading3,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Billable Amount: ${snapshot.data!.$2}",
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
                                            child: TermReportWidget(
                                              teacherId: '',
                                              reportCache: reportCache,
                                              termReports: snapshot.data!.$3,
                                            ),
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
