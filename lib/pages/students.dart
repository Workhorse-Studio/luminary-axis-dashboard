part of axis_dashboard;

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StatefulWidget> createState() => StudentsPageState();
}

class StudentsPageState extends State<StudentsPage> {
  final GenericCache<TermReport> reportCache = GenericCache((classId) async {
    final TermReport tr = TermReport();
    await tr.generateTermReport(classId);
    return tr;
  });
  final (String, TeacherData) allOption = (
    '',
    TeacherData(
      name: 'name',
      role: 'role',
      priorSessionCount: 0,
      classIds: const [],
    ),
  );

  // Admin View State
  (String, TeacherData) currentValue = (
    '',
    TeacherData(
      name: 'name',
      role: 'role',
      priorSessionCount: 0,
      classIds: const [],
    ),
  );
  List<QueryDocumentSnapshot<JSON>> teachersData = [];
  String currentTeacherUid = '';
  String currentTeacherName = '';

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Students',
      body: (context) => TermReportWidget(
        teacherId: auth.currentUser!.uid,
        reportCache: reportCache,
      ),
    );
  }
}

class TermReportWidget extends StatefulWidget {
  final String teacherId;
  final QueryDocumentSnapshot<JSON>? teacherData;
  final GenericCache reportCache;

  const TermReportWidget({
    required this.teacherId,
    required this.reportCache,
    this.teacherData,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => TermReportWidgetState();
}

class TermReportWidgetState extends State<TermReportWidget> {
  final Map<String, ClassData> classesData = {};
  final List<TermReport> termReports = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        final List<String> classIds = TeacherData.fromJson(
          (await firestore.collection('users').doc(widget.teacherId).get())
              .data()!,
        ).classIds;
        for (final classId in classIds) {
          final tr = await widget.reportCache.get(classId);
          classesData[classId] = tr.classData;
          termReports.add(tr);
        }
        return termReports;
      }(),
      builder: (context, snapshot) {
        final List<Widget> widgets = [];

        for (int i = 0; i < classesData.length; i++) {
          final List<DataRow> rows = [];
          final currentReport = termReports[i].data.skip(1).toList();
          for (int j = 0; j < currentReport.length; j++) {
            rows.add(
              DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Text(
                          currentReport[j][0],
                          style: body2,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: LinearProgressIndicator(
                            value: termReports[i].progresses[j],
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final e in currentReport[j].skip(1))
                    DataCell(
                      Text(
                        e.toString(),
                        style: body2,
                      ),
                    ),
                ],
              ),
            );
          }
          widgets.addAll([
            AxisCard(
              header: classesData.values.elementAt(i).name,
              width: MediaQuery.of(context).size.width * 0.7,
              height: null,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    for (final c in termReports[i].data.first)
                      DataColumn(
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
        if (classesData.isEmpty) {
          return Center(
            child: Text(
              'No term reports to show.',
              style: heading3,
            ),
          );
        }
        return widget.teacherData == null
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    if (widget.teacherData != null)
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            TeacherData.fromJson(
                              widget.teacherData!.data(),
                            ).name,
                            style: heading1,
                          ),
                        ),
                      ),
                    ...widgets,
                    const SizedBox(height: 80),
                  ],
                ),
              )
            : Column(
                children: [
                  if (widget.teacherData != null)
                    SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsetsGeometry.only(left: 40),
                          child: Text(
                            TeacherData.fromJson(
                              widget.teacherData!.data(),
                            ).name,
                            style: heading1,
                          ),
                        ),
                      ),
                    ),
                  ...widgets,
                  const SizedBox(height: 80),
                ],
              );
      },
    );
  }
}
