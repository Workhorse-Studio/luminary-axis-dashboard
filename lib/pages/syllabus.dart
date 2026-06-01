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
      pageTitle: 'Attendance',
      actions: [
        AxisButton.text(
          icon: Icons.refresh,
          label: 'Refresh',
          onPressed: () {
            setState(() {
              hasLoaded = false;
            });
          },
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
            return classIds.isEmpty
                ? const <(String, ClassData)>[]
                : (await firestore
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
            return (snapshot.data != null && snapshot.data!.isNotEmpty)
                ? ListView(
                    children: [
                      const SizedBox(height: 30),

                      for (final cl in snapshot.data!) ...[
                        const SizedBox(height: 30),
                        Center(
                          child: AxisCard(
                            header: cl.$2.name,
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: null,
                            child: AxisButton.text(
                              width: 280,
                              height: 70,
                              label: 'Manage Attendance',
                              icon: Icons.ballot,
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (_) =>
                                      AttendanceDialog(classId: cl.$1),
                                );
                                if (context.mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Center(
                    child: Text(
                      'No syllabus sheet to be shown.',
                      style: heading3,
                    ),
                  );
          },
        ),
      ),
    );
  }
}
