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
          AxisDropdownButton(
            width: 140,
            initialSelection: currentStudent ??= studentsData.first,
            onSelected: (value) => setState(() {
              if (value != null) currentStudent = value;
            }),
            entries: [
              for (final student in studentsData)
                (
                  StudentData.fromJson(student.data()).name,
                  student,
                ),
            ],
          ),
        ],
        body: (context) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsetsGeometry.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Allocations',
                  style: heading1,
                ),
                const SizedBox(height: 10),
                if (currentStudent != null)
                  AxisCard(
                    header: '',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: null,
                    child: FutureBuilderTemplate(
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
                                (entry) =>
                                    entry.value.containsKey(
                                      currentStudent!.id,
                                    ) &&
                                    entry.value[currentStudent!.id]!.isPresent,
                              )
                              .length;
                          rows.add(
                            DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    cd.name,
                                    style: body2,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${entry.value}',
                                    style: body2,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${entry.value - numSessionsAttended}',
                                    style: body2,
                                  ),
                                ),
                                DataCell(
                                  AxisNMButton(
                                    label: 'Withdraw',
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              msg,
                                              style: body2,
                                            ),
                                          ),
                                        );
                                      }
                                      setState(() {});
                                    },
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
                                AxisNMButton(
                                  onPressed: () async {
                                    final RegisterForClassData data =
                                        await showDialog(
                                          context: context,
                                          builder: (_) =>
                                              RegisterForClassDialog(
                                                classesDataCache:
                                                    classesDataCache,
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
                                        initialSessionsCount:
                                            data.sessionsCount,
                                      );

                                      await refreshStudentData();

                                      msg = 'Class registered successfully!';
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            msg,
                                            style: body2,
                                          ),
                                        ),
                                      );
                                    }

                                    setState(() {});
                                  },
                                  label: 'Add Class',
                                ),
                              ),
                              DataCell.empty,
                              DataCell.empty,
                              DataCell.empty,
                            ],
                          ),
                        );
                      }(),
                      builder: (context, snapshot) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 80,
                          columns: [
                            DataColumn(
                              label: Text(
                                'Class',
                                style: body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Initial Session Count',
                                style: body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Final Session Count',
                                style: body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(label: Text('')),
                          ],
                          rows: snapshot.data ?? const [],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
