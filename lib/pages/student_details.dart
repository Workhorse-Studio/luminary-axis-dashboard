part of axis_dashboard;

class StudentDetailsPage extends StatefulWidget {
  const StudentDetailsPage({super.key});

  @override
  State<StatefulWidget> createState() => StudentDetailsPageState();
}

class StudentDetailsPageState extends State<StudentDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  late final Query<JSON> _defaultQuery = firestore
      .collection('users')
      .where('role', isEqualTo: 'student');
  List<DataRow> sortedRows = const [];
  late Query<JSON> currentQuery = _defaultQuery;
  List<QueryDocumentSnapshot<JSON>> studentsData = [];
  final Map<String, String> classIdToTeacherNameMap = {};
  final Map<
    String,
    ({TextEditingController iscController, TextEditingController fscController})
  >
  textControllers = {};
  bool sortFSCLowToHigh = false;
  final Set<String> filterClassesIncluded = {};

  final GenericCache<DocumentSnapshot<JSON>> classesDataCache = GenericCache((
    classId,
  ) async {
    return (await firestore.collection('classes').doc(classId).get());
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        if (nameController.text.isNotEmpty) {
          final String searchText =
              "${nameController.text[0].toUpperCase()}${nameController.text.substring(1)}";
          currentQuery = currentQuery.where(
            'name',
            isGreaterThanOrEqualTo: searchText,
            isLessThanOrEqualTo: "$searchText\uf8ff",
          );
        } else {
          currentQuery = _defaultQuery;
        }

        if (studentsData.isEmpty) {
          studentsData = (await currentQuery.get()).docs;
        }
        if (classesDataCache.registry.isEmpty) {
          final docs = (await firestore.collection('classes').get()).docs;
          for (final doc in docs) {
            classesDataCache.registry[doc.id] = doc;
          }
        }
        return studentsData;
      }(),
      builder: (context, snapshot) => Navbar(
        pageTitle: 'Student Details',
        actions: [
          /* AxisDropdownButton(
            width: 150,
            entries: [
              for (final doc in classesDataCache.registry.values)
                (
                  ClassData.fromJson(doc.data()!).name,
                  SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        Checkbox(
                          value: filterClassesIncluded.contains(
                            ClassData.fromJson(doc.data()!).name,
                          ),
                          onChanged: (isSelected) {
                            if (isSelected == null) return;
                            setState(() {
                              if (!isSelected) {
                                filterClassesIncluded.remove(
                                  ClassData.fromJson(doc.data()!).name,
                                );
                              } else {
                                filterClassesIncluded.add(
                                  ClassData.fromJson(doc.data()!).name,
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            onSelected: (selection) {},
          ), */
          SizedBox(
            width: 240,
            height: 50,
            child: TextField(
              controller: nameController,
              onSubmitted: (_) => setState(() {
                studentsData.clear();
              }),
              style: body2,
              decoration: InputDecoration(
                hint: Text(
                  'Search by name',
                  style: body2.copyWith(
                    color: AxisColors.blackPurple20.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AxisColors.lilacPurple20),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AxisColors.lilacPurple50.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 120,
            height: 50,
            child: AxisButton(
              isHighlighted: true,
              onPressed: () => setState(() {
                studentsData.clear();
              }),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.refresh),
                  const SizedBox(width: 8),
                  Text(
                    'Refresh',
                    style: buttonLabel,
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
        body: (context) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsetsGeometry.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                AxisCard(
                  header: '',
                  width: MediaQuery.of(context).size.width * 0.92,
                  height: null,
                  child: FutureBuilderTemplate(
                    future: () async {
                      final List<DataRow> rows = [];
                      for (final currentStudent in studentsData) {
                        for (final entry in StudentData.fromJson(
                          currentStudent.data(),
                        ).initialSessionCount.entries) {
                          final String rowKey =
                              "${currentStudent.id}-${entry.key}";

                          if (!classIdToTeacherNameMap.containsKey(
                            entry.key,
                          )) {
                            classIdToTeacherNameMap[entry.key] =
                                TeacherData.fromJson(
                                  (await firestore
                                          .collection('users')
                                          .where(
                                            'role',
                                            whereIn: const ['teacher', 'admin'],
                                          )
                                          .where(
                                            'classes',
                                            arrayContains: entry.key,
                                          )
                                          .get())
                                      .docs
                                      .first
                                      .data(),
                                ).name;
                          }
                          final String teacherName =
                              classIdToTeacherNameMap[entry.key]!;
                          final cd = ClassData.fromJson(
                            (await classesDataCache.get(
                              entry.key,
                            )).data()!,
                          );
                          /*  if (filterClassesIncluded.isNotEmpty &&
                              !filterClassesIncluded.contains(cd.name)) {
                            continue;
                          } */
                          final numSessionsAttended = cd.attendance.entries
                              .where(
                                (entry) =>
                                    entry.value.containsKey(
                                      currentStudent.id,
                                    ) &&
                                    entry.value[currentStudent.id]!.isPresent,
                              )
                              .length;
                          if (!textControllers.containsKey(rowKey)) {
                            textControllers[rowKey] = (
                              iscController: TextEditingController(
                                text: entry.value.toString(),
                              ),
                              fscController: TextEditingController(
                                text: '${entry.value - numSessionsAttended}',
                              ),
                            );
                          }
                          rows.add(
                            DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    StudentData.fromJson(
                                      currentStudent.data(),
                                    ).name,
                                    style: body2,
                                  ),
                                  onTap: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => StudentInfoDialog(
                                        studentId: currentStudent.id,
                                        studentData: currentStudent,
                                        classIdToTeacherNameMap:
                                            classIdToTeacherNameMap,
                                      ),
                                    );
                                  },
                                ),
                                DataCell(
                                  Text(
                                    cd.name,
                                    style: body2,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    teacherName,
                                    style: body2,
                                  ),
                                ),
                                DataCell(
                                  TextField(
                                    controller:
                                        textControllers[rowKey]!.iscController,
                                    onEditingComplete: () async {
                                      final String msg;
                                      final updatedISC = StudentData.fromJson(
                                        currentStudent.data(),
                                      ).initialSessionCount;
                                      final int? newInt = int.tryParse(
                                        textControllers[rowKey]!
                                            .iscController
                                            .text,
                                      );
                                      if (textControllers[rowKey]!
                                          .iscController
                                          .text
                                          .isEmpty) {
                                        msg = 'Action canclled.';
                                        textControllers[rowKey]!
                                            .iscController
                                            .text = entry.value
                                            .toString();
                                      } else if (newInt != null) {
                                        updatedISC[entry.key] = newInt;
                                        await firestore
                                            .collection('users')
                                            .doc(currentStudent.id)
                                            .update({
                                              'initialSessionCount': updatedISC,
                                            });
                                        textControllers[rowKey]!
                                                .fscController
                                                .text =
                                            '${newInt - numSessionsAttended}';
                                        msg =
                                            'Updated session count successfully!';

                                        //                setState(() {});
                                      } else {
                                        msg =
                                            'Invalid input provided, where only a number was expected. Try again.';
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(msg)),
                                        );
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hint: Text(
                                        textControllers[rowKey]!
                                            .iscController
                                            .value
                                            .text,
                                        style: body2.copyWith(
                                          color: AxisColors.blackPurple20,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AxisColors.lilacPurple20
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AxisColors.lilacPurple50
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    style: body2,
                                  ),
                                ),
                                DataCell(
                                  TextField(
                                    enabled: false,
                                    controller:
                                        textControllers[rowKey]!.fscController,
                                    onEditingComplete: () {},
                                    decoration: InputDecoration(
                                      hint: Text(
                                        textControllers[rowKey]!
                                            .fscController
                                            .value
                                            .text,
                                        style: body2.copyWith(
                                          color: AxisColors.blackPurple20,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AxisColors.lilacPurple20
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AxisColors.lilacPurple50
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
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
                                          studentId: currentStudent.id,
                                          classId: (await classesDataCache.get(
                                            entry.key,
                                          )).id,
                                        );
                                        await refreshStudentData(
                                          currentStudent.id,
                                        );
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
                                          studentId: currentStudent.id,
                                          classId: data.classId,
                                          initialSessionsCount:
                                              data.sessionsCount,
                                        );

                                        await refreshStudentData(
                                          currentStudent.id,
                                        );

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
                              ],
                            ),
                          );
                        }
                      }
                      /**
                       * sorting
                       */
                      return rows;
                    }(),
                    builder: (context, snapshot) {
                      if (!sortFSCLowToHigh) sortedRows = snapshot.data ?? [];
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 80,
                          sortColumnIndex: 3,
                          columns: [
                            DataColumn(
                              label: Text(
                                'Name',
                                style: body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
                                'Teacher',
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
                              onSort: (columnIndex, ascending) {
                                sortFSCLowToHigh = !sortFSCLowToHigh;
                                sortedRows.sort(
                                  (row1, row2) =>
                                      int.parse(
                                        (row1.cells[4].child as TextField)
                                            .controller!
                                            .text,
                                      ).compareTo(
                                        int.parse(
                                          (row2.cells[4].child as TextField)
                                              .controller!
                                              .text,
                                        ),
                                      ),
                                );
                                setState(() {});
                              },
                            ),
                            DataColumn(
                              label: Text(
                                'Actions',
                                style: body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(label: Text('')),
                          ],
                          rows: sortedRows,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> refreshStudentData(String studentId) async {
    final int staleDocIndex = studentsData.indexWhere(
      (doc) => doc.id == studentId,
    );
    studentsData[staleDocIndex] =
        (await firestore
                .collection('users')
                .where(
                  FieldPath.documentId,
                  isEqualTo: studentId,
                )
                .get())
            .docs
            .first;
  }
}
