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
                            child: AxisButton(
                              width: 40,
                              height: 40,
                              onPressed: () async {
                                final Map<String, AttendanceType>? result =
                                    await showDialog(
                                      context: context,
                                      builder: (_) =>
                                          AttendanceDialog(classId: cl.$1),
                                    );
                                final String msg;
                                if (result != null) {
                                  msg = "Attendance updated successfully!";
                                  setState(() {});
                                } else {
                                  msg = "Attendance taking aborted";
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text(msg)));
                                }
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
