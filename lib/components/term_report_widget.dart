part of axis_dashboard;

class TermReportWidget extends StatefulWidget {
  final String teacherId;
  final int termIndex;

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
  late TeacherData teacherData;
  GlobalState? globalState;

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        globalState ??= GlobalState.fromJson(
          (await firestore.collection('global').doc('state').get()).data()!,
        );
        teacherData = TeacherData.fromJson(
          (await firestore.collection('users').doc(widget.teacherId!).get())
              .data()!,
        );
        await studentAttendanceStore.ensureInit(
          globalState: globalState!,
          classesCache: classesCache,
          studentCache: studentCache,
        );
        return 0;
      }(),
      builder: (context, snapshot) {
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
                    dividerThickness: 0.5,
                    border: TableBorder(
                      verticalInside: BorderSide(
                        color: AxisColors.blackPurple20.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      horizontalInside: BorderSide(
                        color: AxisColors.blackPurple20.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
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

        Future<({List<DataRow> rows, String className, List<String> dates})>
        generateReportContent(String classId, int termIndex) async {
          final List<DataRow> rows = [];
          final cd = ClassData.fromJson(
            (await classesCache.get(classId)).data()!,
          );

          final List<String> termDates = [];
          for (final attEntry in cd.attendance.entries) {
            if (monthKeyToTermIndex(globalState!, attEntry.key) == termIndex) {
              termDates.add(attEntry.key);
            }
          }

          termDates.sort((a, b) {
            final aParts = a.split('-');
            final bParts = b.split('-');
            final aDate = DateTime(
              int.parse(aParts[2]),
              int.parse(aParts[1]),
              int.parse(aParts[0]),
            );
            final bDate = DateTime(
              int.parse(bParts[2]),
              int.parse(bParts[1]),
              int.parse(bParts[0]),
            );
            return aDate.compareTo(bDate);
          });

          final allocDoc = await firestore
              .collection('global')
              .doc('state')
              .collection('allocations')
              .doc(globalState!.terms[termIndex].termName)
              .get();

          final TermAllocation allocData =
              (!allocDoc.exists || allocDoc.data() == null)
              ? TermAllocation(sessions: {})
              : TermAllocation.fromJson(allocDoc.data()!);

          final Set<String> studentIds = {};
          for (final date in termDates) {
            studentIds.addAll(cd.attendance[date]!.keys);
          }

          for (final studentId in studentIds) {
            final List<DataCell> studentCells = [];
            final List<String> stringValues = [];

            for (final date in termDates) {
              final studentStatus = cd.attendance[date]![studentId];
              if (studentStatus != null) {
                final str = studentStatus.isPresent
                    ? date.substring(0, date.length - 5)
                    : 'X';
                studentCells.add(DataCell(Text(str, style: body2)));
                stringValues.add(str);
              } else {
                studentCells.add(DataCell(Text(' ', style: body2)));
                stringValues.add(' ');
              }
            }

            int initialCount = allocData.sessions[classId]?[studentId] ?? 0;
            if (initialCount == -1) {
              initialCount = 0;
            }

            int attendedSessions = stringValues
                .where((d) => d != 'X' && d != ' ')
                .length;
            int finalCount = initialCount - attendedSessions;
            double progress = initialCount > 0
                ? (1 - (finalCount / initialCount))
                : 0.0;

            rows.add(
              DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        FutureBuilderTemplate(
                          future: (() async => (StudentData.fromJson(
                            (await studentCache.get(studentId)).data()!,
                          )).name)(),
                          builder: (_, snapshot) => Text(
                            "${snapshot.data}",
                            style: body2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    FutureBuilderTemplate(
                      future: (() async => ClassData.fromJson(
                        (await classesCache.get(classId)).data()!,
                      ).name)(),
                      builder: (_, snapshot) => Text(
                        snapshot.data!,
                        style: body2,
                      ),
                    ),
                  ),
                  ...studentCells,
                  DataCell(
                    Text(
                      '$initialCount',
                      style: body2,
                    ),
                  ),
                  DataCell(
                    Text(
                      '$finalCount',
                      style: body2,
                    ),
                  ),
                ],
              ),
            );
          }
          return (
            rows: rows,
            className: cd.name,
            dates: termDates
                .map((date) => date.substring(0, date.length - 5))
                .toList(),
          );
        }

        // createWidgetsForReport(widget.termIndex);
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
          child: Column(
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
                      teacherData.name,
                      style: heading1,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      for (final clId in teacherData.classIds) ...[
                        FutureBuilderTemplate(
                          future: generateReportContent(clId, widget.termIndex),
                          builder: (context, snapshot) => AxisCard(
                            header: snapshot.data!.className,
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: null,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                dividerThickness: 0.5,
                                border: TableBorder(
                                  verticalInside: BorderSide(
                                    color: AxisColors.blackPurple20.withValues(
                                      alpha: 0.15,
                                    ),
                                    width: 1,
                                  ),
                                  horizontalInside: BorderSide(
                                    color: AxisColors.blackPurple20.withValues(
                                      alpha: 0.15,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                columns: [
                                  for (final c in [
                                    'Name',
                                    'Level',
                                    ...snapshot.data!.dates,
                                    'Initial Count',
                                    'Final Count',
                                  ])
                                    DataColumn(
                                      columnWidth: IntrinsicColumnWidth(
                                        flex: 1,
                                      ),
                                      label: Text(
                                        c.toString(),
                                        style: body2.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                                rows: snapshot.data!.rows,
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
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
