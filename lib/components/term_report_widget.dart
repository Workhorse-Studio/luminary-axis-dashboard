part of axis_dashboard;

class TermReportWidget extends StatefulWidget {
  final String? teacherId;
  final int? termIndex;

  const TermReportWidget({
    required this.teacherId,
    required this.termIndex,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => TermReportWidgetState();
}

class TermReportWidgetState extends State<TermReportWidget> {
  final GenericCache<DocumentSnapshot<JSON>> studentCache = GenericCache(
    (studentId) async =>
        await firestore.collection('users').doc(studentId).get(),
  );
  final GenericCache<DocumentSnapshot<JSON>> classesCache = GenericCache(
    (classId) async => await firestore.collection('classes').doc(classId).get(),
  );
  TeacherData? teacherData;
  GlobalState? globalState;

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        globalState ??= GlobalState.fromJson(
          (await firestore.collection('global').doc('state').get()).data()!,
        );
        if (widget.teacherId != null) {
          teacherData = TeacherData.fromJson(
            (await firestore.collection('users').doc(widget.teacherId!).get())
                .data()!,
          );
        }
        await studentAttendanceStore.ensureInit(
          globalState: globalState!,
          classesCache: classesCache,
          studentCache: studentCache,
        );
        return 0;
      }(),
      builder: (context, snapshot) {
        print('Y');
        final List<Widget> widgets = [];

        bool createWidgetsForReport(int termIndex) {
          final List<DataRow> rows = [];
          final Map<String, Map<String, List<String?>>> currentTerm =
              studentAttendanceStore.termReports[termIndex];

          bool empty = true;
          int numSessionsForClass = 0;
          for (final studentEntry in currentTerm.entries) {
            for (final classEntry in studentEntry.value.entries) {
              empty = false;
              rows.add(
                DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          FutureBuilderTemplate(
                            future: (() async => (StudentData.fromJson(
                              (await studentCache.get(
                                studentEntry.key,
                              )).data()!,
                            )).name)(),
                            builder: (_, snapshot) => Text(
                              "${snapshot.data}",
                              style: body2,
                            ),
                          ),

                          const SizedBox(width: 10),
                          Flexible(
                            child: LinearProgressIndicator(
                              value: 0, // termReport.progresses[j],
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        'Lvl',
                        style: body2,
                      ),
                    ),
                    for (final str in classEntry.value)
                      DataCell(
                        Text(
                          str ?? '',
                          style: body2,
                        ),
                      ),
                    DataCell(
                      Text(
                        '0',
                        style: body2,
                      ),
                    ),
                    DataCell(
                      Text(
                        '0',
                        style: body2,
                      ),
                    ),
                  ],
                ),
              );
            }
            widgets.addAll([
              AxisCard(
                header: teacherData?.name ?? '',
                width: MediaQuery.of(context).size.width * 0.85,
                height: null,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      for (final c in [
                        'Name',
                        'Level',
                        for (final str in studentEntry.value.values.first)
                          'Date',
                        'Initial Count',
                        'Final Count',
                      ])
                        DataColumn(
                          columnWidth: IntrinsicColumnWidth(flex: 1),
                          label: Text(
                            c.toString(),
                            style: body2.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                    rows: rows,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ]);
          }
          return empty;
        }

        createWidgetsForReport(widget.termIndex ?? globalState!.currentTermNum);
        /* if (createWidgetsForReport(
          widget.termIndex ?? globalState!.currentTermNum,
        )) {
          return Center(
            child: Text(
              'No attendance information to show.',
              style: heading3,
            ),
          );
        } */
        return Padding(
          padding: const EdgeInsets.only(left: 40, right: 40),
          child: teacherData == null
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      ...widgets,
                      const SizedBox(height: 80),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsetsGeometry.only(left: 40),
                          child: Text(
                            teacherData!.name,
                            style: heading1,
                          ),
                        ),
                      ),
                    ),
                    ...widgets,
                    const SizedBox(height: 80),
                  ],
                ),
        );
      },
    );
  }
}
