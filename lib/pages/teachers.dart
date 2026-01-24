part of axis_dashboard;

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<StatefulWidget> createState() => TeachersPageState();
}

class TeachersPageState extends State<TeachersPage> {
  (String, QueryDocumentSnapshot<JSON>)? currentTeacher;
  List<QueryDocumentSnapshot<JSON>> teachersData = [];
  bool showTermReport = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        final query = firestore
            .collection('users')
            .where('role', isEqualTo: 'teacher');
        teachersData = (await query.get()).docs;

        return teachersData;
      }(),
      builder: (context, snapshot) {
        return Navbar(
          pageTitle: 'Teachers',
          actions: [
            DropdownMenu<(String, QueryDocumentSnapshot<JSON>)>(
              initialSelection: currentTeacher ??= (
                teachersData.first.id,
                teachersData.first,
              ),
              dropdownMenuEntries: [
                for (final tData in teachersData)
                  DropdownMenuEntry(
                    value: (tData.id, tData),
                    label: TeacherData.fromJson(tData.data()).name,
                  ),
              ],
              onSelected: (newTData) => setState(() {
                if (newTData != null) currentTeacher = newTData;
              }),
            ),
          ],
          body: (context) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
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
                    '${TeacherData.fromJson(currentTeacher!.$2.data()).name} ${snapshot.data} Attendance Sheet',
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
                    const Text('Show Term Report'),
                  ],
                ),
                if (showTermReport)
                  TermReportWidget(
                    teacherId: currentTeacher!.$1,
                    teacherData: currentTeacher!.$2,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
