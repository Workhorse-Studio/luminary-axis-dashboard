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
                for (final cl in snapshot.data!)
                  ListTile(
                    title: Text(cl.$2.name),
                    trailing: TextButton(
                      onPressed: () async {
                        final Map<String, ({String name, bool present})>
                        result = await showDialog(
                          context: context,
                          builder: (_) => AttendanceDialog(classId: cl.$1),
                        );
                        final now = DateTime.now();
                        final String todayId =
                            '${now.day}-${now.month}-${now.year}';
                        final List<String> presentIds = [];
                        for (final r in result.entries) {
                          if (r.value.present) presentIds.add(r.key);
                        }

                        final newAttendance = cl.$2.attendance;
                        newAttendance[todayId] = presentIds;
                        await firestore.collection('classes').doc(cl.$1).update(
                          {'attendance': newAttendance},
                        );
                      },
                      child: Icon(Icons.ballot),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
