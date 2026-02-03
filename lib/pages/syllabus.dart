part of axis_dashboard;

class SyllabusPage extends StatefulWidget {
  const SyllabusPage({super.key});

  @override
  State<StatefulWidget> createState() => SyllabusPageState();
}

class SyllabusPageState extends State<SyllabusPage> {
  Iterable<Map> snapshots = [];
  bool hasLoaded = false;
  bool isAdmin = false;

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Syllabus',
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              hasLoaded = false;
            });
          },
          child: Wrap(
            children: [
              Icon(Icons.refresh),
              const SizedBox(width: 10),
              Text('Refresh'),
            ],
          ),
        ),
      ],
      body: (ctx) => Center(
        child: FutureBuilderTemplate(
          future: () async {
            final teacherData =
                (await firestore
                        .collection('users')
                        .doc(auth.currentUser!.uid)
                        .get())
                    .data();

            final classIds = TeacherData.fromJson(teacherData!).classIds;
            return (await firestore
                    .collection('classes')
                    .where(
                      FieldPath.documentId,
                      whereIn: classIds,
                    )
                    .get())
                .docs
                .map((doc) => (doc.id, ClassData.fromJson(doc.data())))
                .toList();
          }(),
          builder: (ctx, snapshot) {
            return ListView(
              children: [
                for (final cl in snapshot.data!) ...[
                  const SizedBox(height: 30),
                  Center(
                    child: AxisCard(
                      header: cl.$2.name,
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: null,
                      child: AxisButton(
                        width: 40,
                        height: 40,
                        onPressed: () async {
                          final Map<String, AttendanceType> result =
                              await showDialog(
                                context: context,
                                builder: (_) =>
                                    AttendanceDialog(classId: cl.$1),
                              );
                          final now = DateTime.now();
                          final String todayId =
                              '${now.day}-${now.month}-${now.year}';

                          final newAttendance = cl.$2.attendance;
                          for (final r in result.entries) {
                            newAttendance[todayId]![r.key] = r.value;
                          }

                          await firestore
                              .collection('classes')
                              .doc(cl.$1)
                              .update(
                                {'attendance': newAttendance.toJson()},
                              );
                        },
                        child: Icon(
                          Icons.ballot,
                          size: 30,
                          color: AxisColors.blackPurple20,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
