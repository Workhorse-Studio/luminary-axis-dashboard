part of axis_dashboard;

class TermDetailsPage extends StatefulWidget {
  const TermDetailsPage({super.key});

  @override
  State<StatefulWidget> createState() => TermDetailsPageState();
}

typedef ClassAllocations = Map<String, int>;

class TermDetailsPageState extends State<TermDetailsPage> {
  int currentTabIndex = 0;
  GlobalState? globalState;
  bool sortASC = false, sortRSC = false;
  final Map<String, TextEditingController> controllers = {};
  final Map<String, String> classIdToTeacherNameMap = {};
  final TextEditingController filterStudentMenuController =
          TextEditingController(),
      filterClassMenuController = TextEditingController(),
      filterISCMenuController = TextEditingController(),
      filterFSCMenuController = TextEditingController();
  final GenericCache<DocumentSnapshot<JSON>> allocationsCache = GenericCache(
    (termName) async => (await firestore
        .collection('global')
        .doc('state')
        .collection('allocations')
        .doc(termName)
        .get()),
  );
  final TextEditingController termNameController = TextEditingController();

  final GenericCache<DocumentSnapshot<JSON>> classesCache = GenericCache(
    (classId) async =>
        (await firestore.collection('classes').doc(classId).get()),
  );
  final GenericCache<DocumentSnapshot<JSON>> studentsCache = GenericCache(
    (studentId) async =>
        (await firestore.collection('users').doc(studentId).get()),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        globalState ??= GlobalState.fromJson(
          (await firestore.collection('global').doc('state').get()).data()!,
        );
        await classesCache.initAll(collection: firestore.collection('classes'));
        await studentsCache.initAll(
          query: firestore
              .collection('users')
              .where('role', isEqualTo: 'student'),
        );
        termNameController.text = globalState!.terms[currentTabIndex].termName;
        return globalState;
      }(),

      builder: (context, snapshot) => Navbar(
        pageTitle: 'Term Details',
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            key: ValueKey(currentTabIndex),
            children: [
              Text(
                'Start: ${DateTime.fromMillisecondsSinceEpoch(globalState!.terms[currentTabIndex].termStartDate).toTimestampStringShort()}',
                style: body2,
              ),
              const SizedBox(height: 6),
              Text(
                'End: ${DateTime.fromMillisecondsSinceEpoch(globalState!.terms[currentTabIndex].termEndDate).toTimestampStringShort()}',
                style: body2,
              ),
            ],
          ),
          const SizedBox(width: 10),
          AxisButton.text(
            label: 'Modify End Date',
            onPressed: () async {
              final endDate = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(
                  const Duration(days: 30 * 6),
                ),
                lastDate: DateTime.now().add(const Duration(days: 30 * 6)),
              );
              if (endDate == null) return;

              final bool? confirm = await showDialog(
                context: context,
                builder: (_) => ConfirmationDialog(
                  confirmationMsg:
                      'Are you sure you want to adjust the term end date? This will shift all subsequent term start/end dates.',
                ),
              );
              if (confirm == null || !confirm) return;
              final List<TermData> newData = [
                ...globalState!.terms.sublist(
                  0,
                  currentTabIndex,
                ),
                TermData(
                  termEndDate: endDate.millisecondsSinceEpoch,
                  termName: globalState!.terms[currentTabIndex].termName,
                  termStartDate:
                      globalState!.terms[currentTabIndex].termStartDate,
                ),
              ];
              Duration? delta;
              for (
                int i = currentTabIndex + 1;
                i < globalState!.terms.length;
                i++
              ) {
                delta ??= DateTime.fromMillisecondsSinceEpoch(
                  globalState!.terms[i].termStartDate,
                ).difference(endDate);
                if (delta.isNegative) {
                  newData.add(
                    TermData(
                      termEndDate:
                          globalState!.terms[i].termEndDate +
                          delta.abs().inMilliseconds +
                          1000,
                      termName: globalState!.terms[i].termName,
                      termStartDate:
                          globalState!.terms[i].termStartDate +
                          delta.abs().inMilliseconds +
                          1000,
                    ),
                  );
                } else {
                  break;
                }
              }
              await firestore.collection('global').doc('state').update({
                'terms': newData.map((e) => e.toJson()),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Term end date set successfully!',
                      style: body2,
                    ),
                  ),
                );
                globalState = GlobalState.fromJson(
                  (await firestore.collection('global').doc('state').get())
                      .data()!,
                );
              }

              setState(() {});
            },
          ),
          const SizedBox(width: 60),
          SizedBox(
            width: 240,
            height: 50,
            child: TextField(
              controller: termNameController,
              onSubmitted: (newTermName) async {
                final String oldName =
                    globalState!.terms[currentTabIndex].termName;
                await firestore
                    .collection('global')
                    .doc('state')
                    .collection('allocations')
                    .doc(newTermName)
                    .set(
                      (await allocationsCache.get(
                        oldName,
                      )).data()!,
                    );
                allocationsCache.registry.remove(oldName);
                allocationsCache.registry[newTermName] = await firestore
                    .collection('global')
                    .doc('state')
                    .collection('allocations')
                    .doc(newTermName)
                    .get();
                await firestore
                    .collection('global')
                    .doc('state')
                    .collection('allocations')
                    .doc(oldName)
                    .delete();
                await firestore.collection('global').doc('state').update({
                  'terms': [
                    for (final term in globalState!.terms)
                      term.termName == oldName
                          ? TermData(
                              termEndDate: term.termEndDate,
                              termName: newTermName,
                              termStartDate: term.termStartDate,
                            ).toJson()
                          : term.toJson(),
                  ],
                });
                setState(() {});
              },
              style: body2,
              decoration: InputDecoration(
                hint: Text(
                  termNameController.text,
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
          AxisButton.text(
            label: 'New Term',
            onPressed: () async {
              String recursivelyNameNewTerm(String prevName) {
                final dupNames = globalState!.terms.where(
                  (t) => t.termName == prevName,
                );
                if (dupNames.isNotEmpty) {
                  return recursivelyNameNewTerm('$prevName ${dupNames.length}');
                } else {
                  return prevName;
                }
              }

              String termName = recursivelyNameNewTerm('Term ${termNum + 2}');

              await firestore
                  .collection('global')
                  .doc('state')
                  .collection('allocations')
                  .doc(termName)
                  .set(
                    TermAllocation(
                      sessions: {
                        for (final classData in classesCache.registry.entries)
                          classData.key: {
                            for (final studentId in ClassData.fromJson(
                              classData.value.data()!,
                            ).studentIds)
                              studentId: 0,
                          },
                      },
                    ).toJson(),
                  );
              await firestore.collection('global').doc('state').update({
                'terms': [
                  ...globalState!.terms.map((t) => t.toJson()),
                  TermData(
                    termEndDate:
                        globalState!.terms.last.termEndDate +
                        Duration(days: 1).inMilliseconds +
                        Duration(days: 30 * 3).inMilliseconds,
                    termName: termName,
                    termStartDate:
                        globalState!.terms.last.termEndDate +
                        Duration(days: 1).inMilliseconds,
                  ).toJson(),
                ],
              });
              globalState = GlobalState.fromJson(
                (await firestore.collection('global').doc('state').get())
                    .data()!,
              );
              setState(() {});
            },
          ),
        ],
        body: (context) => DefaultTabController(
          length: globalState!.terms.length,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 60,
                  child: Row(
                    children: [
                      createFilterMenu(
                        context,
                        controller: filterStudentMenuController,
                        entries: [
                          for (final studentEntry
                              in studentsCache.registry.entries)
                            DropdownMenuEntry(
                              label: StudentData.fromJson(
                                studentEntry.value.data()!,
                              ).name,
                              value: studentEntry.value,
                              style: menuEntryStyle,
                            ),
                        ],
                      ),
                      const SizedBox(width: 30),
                      createFilterMenu(
                        context,
                        controller: filterClassMenuController,
                        entries: [
                          for (final classEntry
                              in classesCache.registry.entries)
                            DropdownMenuEntry(
                              label: ClassData.fromJson(
                                classEntry.value.data()!,
                              ).name,
                              value: classEntry.value,
                              style: menuEntryStyle,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  key: ValueKey(
                    globalState!.terms.map((t) => t.termName).join('-'),
                  ),
                  onTap: (index) {
                    currentTabIndex = index;
                    termNameController.text =
                        globalState!.terms[index].termName;
                    setState(() {});
                  },
                  tabs: [
                    for (final term in globalState!.terms)
                      Tab(
                        text: term.termName,
                      ),
                  ],
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - 190,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TabBarView(
                      children: [
                        for (final term in globalState!.terms)
                          FutureBuilderTemplate(
                            future: () async {
                              final allocations = (await allocationsCache.get(
                                term.termName,
                              ));
                              if (allocations.exists) {
                                return allocations;
                              } else {
                                final currentTermName = globalState!
                                    .terms[globalState!.currentTermNum]
                                    .termName;
                                final currentTermAllocations =
                                    (await allocationsCache.get(
                                      currentTermName,
                                    ));
                                if (currentTermAllocations.exists) {
                                  (await firestore
                                      .collection('global')
                                      .doc('state')
                                      .collection('allocations')
                                      .doc(term.termName)
                                      .set(currentTermAllocations.data()!));

                                  allocationsCache.registry[term.termName] =
                                      await firestore
                                          .collection('global')
                                          .doc('state')
                                          .collection('allocations')
                                          .doc(term.termName)
                                          .get();
                                } else {
                                  final newAllocations = TermAllocation(
                                    sessions: {
                                      for (final classData
                                          in classesCache.registry.entries)
                                        classData.key: {
                                          for (final studentId
                                              in ClassData.fromJson(
                                                classData.value.data()!,
                                              ).studentIds)
                                            studentId: 0,
                                        },
                                    },
                                  );

                                  for (final tname in [
                                    term.termName,
                                    currentTermName,
                                  ]) {
                                    (await firestore
                                        .collection('global')
                                        .doc('state')
                                        .collection('allocations')
                                        .doc(tname)
                                        .set(newAllocations.toJson()));
                                    allocationsCache.registry[tname] =
                                        (await firestore
                                            .collection('global')
                                            .doc('state')
                                            .collection('allocations')
                                            .doc(tname)
                                            .get());
                                  }
                                }
                                return (await allocationsCache.get(
                                  term.termName,
                                ));
                              }
                            }(),
                            builder: (context, snapshot) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                FutureBuilderTemplate(
                                  future: () async {
                                    final List<DataRow> rows = [];
                                    for (final entry in TermAllocation.fromJson(
                                      snapshot.data!.data()!,
                                    ).sessions.entries) {
                                      final classData = ClassData.fromJson(
                                        (await classesCache.get(
                                          entry.key,
                                        )).data()!,
                                      );
                                      if (filterClassMenuController.text !=
                                              'None' &&
                                          filterClassMenuController.text !=
                                              classData.name) {
                                        continue;
                                      }
                                      rows.add(
                                        DataRow(
                                          color: WidgetStatePropertyAll(
                                            AxisColors.blackPurple20.withValues(
                                              alpha: 0.14,
                                            ),
                                          ),
                                          cells: [
                                            DataCell(
                                              RichText(
                                                text: TextSpan(
                                                  text: classData.name,
                                                  style: heading3,
                                                  children: [
                                                    TextSpan(
                                                      style: body2,
                                                      text:
                                                          "     by ${!classIdToTeacherNameMap.containsKey(entry.key) ? classIdToTeacherNameMap[entry.key] = TeacherData.fromJson(
                                                                  (await firestore.collection(
                                                                    'users',
                                                                  ).where(
                                                                    'role',
                                                                    whereIn: const [
                                                                      'teacher',
                                                                      'admin',
                                                                    ],
                                                                  ).where(
                                                                    'classes',
                                                                    arrayContains: entry.key,
                                                                  ).get()).docs.first.data(),
                                                                ).name : classIdToTeacherNameMap[entry.key]}",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            DataCell.empty,
                                            DataCell.empty,
                                            DataCell.empty,
                                          ],
                                        ),
                                      );
                                      /* int startIndex = 1;
                                      int numEntriesAdded = 0; */
                                      for (final studentEntry
                                          in entry.value.entries) {
                                        final studentData =
                                            StudentData.fromJson(
                                              (await studentsCache.get(
                                                studentEntry.key,
                                              )).data()!,
                                            );
                                        if (filterStudentMenuController.text !=
                                                'None' &&
                                            filterStudentMenuController.text !=
                                                studentData.name) {
                                          continue;
                                        }
                                        //  numEntriesAdded += 1;
                                        final rowKey =
                                            "${entry.key}-${studentEntry.key}";
                                        if (!controllers.containsKey(rowKey)) {
                                          controllers[rowKey] =
                                              TextEditingController(
                                                text: studentEntry.value
                                                    .toString(),
                                              );
                                        }
                                        rows.add(
                                          DataRow(
                                            color: studentEntry.value != -1
                                                ? null
                                                : WidgetStatePropertyAll(
                                                    Colors.yellow.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                  ),
                                            cells: [
                                              DataCell(
                                                Text(
                                                  studentData.name,
                                                  style: body2,
                                                ),
                                                onTap: () async {
                                                  final sd = await studentsCache
                                                      .get(studentEntry.key);
                                                  await showDialog(
                                                    context: context,
                                                    builder: (_) => StudentInfoDialog(
                                                      studentId:
                                                          studentEntry.key,
                                                      studentData: sd,
                                                      classIdToTeacherNameMap:
                                                          classIdToTeacherNameMap,
                                                    ),
                                                  );
                                                },
                                              ),
                                              DataCell(
                                                TextField(
                                                  controller:
                                                      controllers[rowKey]!,
                                                  onEditingComplete: () async {
                                                    final String msg;

                                                    final int?
                                                    newInt = int.tryParse(
                                                      controllers[rowKey]!.text,
                                                    );
                                                    if (controllers[rowKey]!
                                                        .text
                                                        .isEmpty) {
                                                      msg = 'Action canclled.';
                                                      controllers[rowKey]!
                                                          .text = studentEntry
                                                          .value
                                                          .toString();
                                                    } else if (newInt != null) {
                                                      await firestore
                                                          .collection('global')
                                                          .doc('state')
                                                          .collection(
                                                            'allocations',
                                                          )
                                                          .doc(term.termName)
                                                          .update({
                                                            '${entry.key}.${studentEntry.key}':
                                                                newInt,
                                                          });
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
                                                        SnackBar(
                                                          content: Text(msg),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  decoration: InputDecoration(
                                                    hint: Text(
                                                      controllers[rowKey]!
                                                          .value
                                                          .text,
                                                      style: body2.copyWith(
                                                        color: AxisColors
                                                            .blackPurple20,
                                                      ),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: AxisColors
                                                                .lilacPurple20
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                ),
                                                          ),
                                                        ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: AxisColors
                                                                .lilacPurple50
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                          ),
                                                        ),
                                                  ),
                                                  style: body2,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  "${int.parse(controllers[rowKey]!.text) - classData.attendance.entries.where(
                                                        (entry) => entry.value.containsKey(
                                                              studentEntry.key,
                                                            ) && entry.value[studentEntry.key]!.isPresent,
                                                      ).length}",
                                                  style: body2,
                                                ),
                                              ),
                                              DataCell(
                                                AxisNMButton(
                                                  label: 'Withdraw',
                                                  onPressed: () async {
                                                    final bool
                                                    confirm = await showDialog(
                                                      context: context,
                                                      builder: (_) =>
                                                          ConfirmationDialog(
                                                            confirmationMsg:
                                                                'Are you sure you would like to withdraw from class "${classData.name}"?',
                                                          ),
                                                    );
                                                    final String msg;
                                                    if (confirm) {
                                                      await withdrawStudentFromClass(
                                                        studentId:
                                                            studentEntry.key,
                                                        classId:
                                                            (await classesCache
                                                                    .get(
                                                                      entry.key,
                                                                    ))
                                                                .id,
                                                      );
                                                      await classesCache.get(
                                                        entry.key,
                                                        bypassCache: true,
                                                      );
                                                      studentsCache.get(
                                                        studentEntry.key,
                                                        bypassCache: true,
                                                      );
                                                      setState(() {});
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
                                      if (rows.last.cells[1] ==
                                          DataCell.empty) {
                                        rows.removeLast();
                                      } /* else {
                                        rows.replaceRange(
                                          startIndex,
                                          startIndex + numEntriesAdded,
                                          rows.sublist(
                                            startIndex,
                                            startIndex + numEntriesAdded + 1,
                                          ).,
                                        );

                                        startIndex = rows.length - 1;
                                      } */
                                    }

                                    return rows;
                                  }(),
                                  builder: (context, snapshot) => Align(
                                    alignment: Alignment.topLeft,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: DataTable(
                                          dataRowMinHeight: 60,
                                          dataRowMaxHeight: 80,
                                          columns: [
                                            DataColumn(
                                              columnWidth: FixedColumnWidth(
                                                280,
                                              ),
                                              label: Text(
                                                'Name',
                                                style: body2.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),

                                            DataColumn(
                                              onSort: (columnIndex, ascending) {
                                                setState(() {
                                                  sortASC = ascending;
                                                });
                                              },
                                              label: Text(
                                                'Allocated Session Count',
                                                style: body2.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              onSort: (columnIndex, ascending) {
                                                setState(() {
                                                  sortRSC = ascending;
                                                });
                                              },
                                              label: Text(
                                                'Remaining Session Count',
                                                style: body2.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataColumn(
                                              label: const SizedBox(),
                                            ),
                                          ],
                                          rows: snapshot.data ?? const [],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                      ],
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

  Widget createFilterMenu<T>(
    BuildContext context, {
    required TextEditingController controller,
    required List<DropdownMenuEntry<T>> entries,
  }) => DropdownMenu(
    leadingIcon: controller.value.text != 'None' ? Icon(Icons.check) : null,
    controller: controller,
    inputDecorationTheme: InputDecorationTheme(
      border: InputBorder.none,
      contentPadding: EdgeInsets.only(left: 20),
    ),
    menuStyle: MenuStyle(
      side: WidgetStatePropertyAll(
        BorderSide(color: AxisColors.blackPurple20),
      ),
      backgroundColor: WidgetStatePropertyAll(
        AxisColors.blackPurple30,
      ),
    ),
    dropdownMenuEntries: [
      DropdownMenuEntry(
        label: 'None',
        value: null,
        style: menuEntryStyle,
      ),
      ...entries,
    ],
    onSelected: (_) {
      setState(() {});
    },
  );
}
