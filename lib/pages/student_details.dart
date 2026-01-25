part of axis_dashboard;

class StudentDetailsPage extends StatefulWidget {
  const StudentDetailsPage({super.key});

  @override
  State<StatefulWidget> createState() => StudentDetailsPageState();
}

class StudentDetailsPageState extends State<StudentDetailsPage> {
  List<QueryDocumentSnapshot<JSON>> studentsData = [];
  QueryDocumentSnapshot<JSON>? currentStudent;
  final GenericCache<DocumentSnapshot<JSON>> classesDataCache = GenericCache((
    classId,
  ) async {
    return (await firestore.collection('classes').doc(classId).get());
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        if (studentsData.isEmpty) {
          studentsData =
              (await firestore
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .get())
                  .docs;
        }
        return studentsData;
      }(),
      builder: (context, snapshot) => Navbar(
        pageTitle: 'Student Details',
        actions: [
          DropdownMenu(
            initialSelection: currentStudent ??= studentsData.first,
            onSelected: (value) => setState(() {
              if (value != null) currentStudent = value;
            }),
            dropdownMenuEntries: [
              for (final student in studentsData)
                DropdownMenuEntry(
                  value: student,
                  label: StudentData.fromJson(student.data()).name,
                ),
            ],
          ),
        ],
        body: (context) => SingleChildScrollView(
          child: Column(
            children: [
              const Text('Session Allocations'),
              const SizedBox(height: 10),
              if (currentStudent != null)
                FutureBuilderTemplate(
                  key: ValueKey(currentStudent!.id),
                  future: () async {
                    final List<DataRow> rows = [];
                    for (final entry in StudentData.fromJson(
                      currentStudent!.data(),
                    ).initialSessionCount.entries) {
                      final cd = ClassData.fromJson(
                        (await classesDataCache.get(entry.key)).data()!,
                      );
                      final numSessionsAttended = cd.attendance.entries
                          .where(
                            (entry) => entry.value.contains(currentStudent!.id),
                          )
                          .length;
                      rows.add(
                        DataRow(
                          cells: [
                            DataCell(Text(cd.name)),
                            DataCell(Text('${entry.value}')),
                            DataCell(
                              Text('${entry.value - numSessionsAttended}'),
                            ),
                            DataCell(
                              TextButton(
                                onPressed: () async {
                                  final bool confirm = await showDialog(
                                    context: context,
                                    builder: (_) => ConfirmationDialog(
                                      confirmationMsg:
                                          'Are you sure you would like to withdraw from class "${cd.name}"?',
                                    ),
                                  );
                                  final String msg;
                                  if (confirm) {
                                    await withdrawStudentFromClass(
                                      studentId: currentStudent!.id,
                                      classId: (await classesDataCache.get(
                                        entry.key,
                                      )).id,
                                    );
                                    await refreshStudentData();
                                    msg =
                                        'Withdrawn student from class successfully!';
                                  } else {
                                    msg = 'Action cancelled';
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                  }
                                  setState(() {});
                                },
                                child: Text('Withdraw'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return rows..add(
                      DataRow(
                        cells: [
                          DataCell(
                            TextButton(
                              onPressed: () async {
                                final RegisterForClassData data =
                                    await showDialog(
                                      context: context,
                                      builder: (_) => RegisterForClassDialog(
                                        classesDataCache: classesDataCache,
                                      ),
                                    );
                                final msg;
                                if (data.classId == '' ||
                                    data.sessionsCount == -1) {
                                  msg = 'Class registration cancelled';
                                } else {
                                  await registerStudentForClass(
                                    studentId: currentStudent!.id,
                                    classId: data.classId,
                                    initialSessionsCount: data.sessionsCount,
                                  );

                                  await refreshStudentData();

                                  msg = 'Class registered successfully!';
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        msg,
                                      ),
                                    ),
                                  );
                                }

                                setState(() {});
                              },
                              child: Text('Add Class'),
                            ),
                          ),
                          DataCell.empty,
                          DataCell.empty,
                          DataCell.empty,
                        ],
                      ),
                    );
                  }(),
                  builder: (context, snapshot) => DataTable(
                    columns: [
                      DataColumn(label: Text('Class')),
                      DataColumn(label: Text('Initial Session Count')),
                      DataColumn(label: Text('Final Session Count')),
                      DataColumn(label: Text('')),
                    ],
                    rows: snapshot.data ?? const [],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> refreshStudentData() async {
    final int staleDocIndex = studentsData.indexWhere(
      (doc) => doc.id == currentStudent!.id,
    );
    studentsData[staleDocIndex] =
        (await firestore
                .collection('users')
                .where(
                  FieldPath.documentId,
                  isEqualTo: currentStudent!.id,
                )
                .get())
            .docs
            .first;
  }
}
