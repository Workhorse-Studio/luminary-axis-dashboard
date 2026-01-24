part of axis_dashboard;

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StatefulWidget> createState() => StudentsPageState();
}

class StudentsPageState extends State<StudentsPage> {
  final Map<String, ClassData> classesData = {};
  final List<TermReport> termReports = [];
  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Students',
      body: (context) => FutureBuilderTemplate(
        future: () async {
          final List<String> classIds = TeacherData.fromJson(
            (await firestore
                    .collection('users')
                    .doc(auth.currentUser!.uid)
                    .get())
                .data()!,
          ).classIds;
          for (final classId in classIds) {
            final tr = TermReport();
            await tr.generateTermReport(classId);
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
                          Text(currentReport[j][0]),
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
                      DataCell(Text(e.toString())),
                  ],
                ),
              );
            }
            widgets.addAll(
              [
                ListTile(
                  title: Text(classesData.values.elementAt(i).name),
                  tileColor: Colors.deepPurple,
                ),
                DataTable(
                  columns: [
                    for (final c in termReports[i].data.first)
                      DataColumn(label: Text(c.toString())),
                  ],
                  rows: rows,
                ),
              ],
            );
          }
          return ListView(
            children: widgets,
          );
        },
      ),
    );
  }
}
