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
  final CollectionReference<JSON> allocsColl = firestore
      .collection('global')
      .doc('state')
      .collection('allocations');
  final Map<String, TextEditingController> controllers = {};
  final Map<String, String> classIdToTeacherNameMap = {};
  final TextEditingController filterStudentMenuController =
          TextEditingController(text: 'None'),
      filterClassMenuController = TextEditingController(text: 'None'),
      filterISCMenuController = TextEditingController(),
      filterFSCMenuController = TextEditingController(),
      allocateAllSessionsController = TextEditingController();

  final TextEditingController termNameController = TextEditingController();

  final GenericCache<DocumentSnapshot<JSON>> classesCache = GenericCache(
    (classId) async =>
        (await firestore.collection('classes').doc(classId).get()),
  );
  final GenericCache<DocumentSnapshot<JSON>> studentsCache = GenericCache(
    (studentId) async =>
        (await firestore.collection('users').doc(studentId).get()),
  );
  final GenericCache<DocumentSnapshot<JSON>> allocationsCache = GenericCache(
    (id) async => (await firestore
        .collection('global')
        .doc('state')
        .collection('allocations')
        .doc(id)
        .get()),
  );
  List<(DocumentSnapshot<JSON>, String)> visibleRows = [];
  List<Widget> tabViews = [];

  @override
  Widget build(BuildContext context) {
    visibleRows.clear();

    return FutureBuilderTemplate(
      future: () async {
        if (globalState != null) return globalState;
        globalState ??= GlobalState.fromJson(
          (await firestore.collection('global').doc('state').get()).data()!,
        );
        await allocationsCache.initAll(collection: allocsColl);
        await classesCache.initAll(collection: firestore.collection('classes'));
        await studentsCache.initAll(
          query: firestore
              .collection('users')
              .where('role', isEqualTo: 'student'),
        );
        termNameController.text = globalState!.terms[currentTabIndex].termName;
        setState(() {});
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
                final oldTerm = globalState!.terms[currentTabIndex];
                final newTerm = TermData(
                  termEndDate: oldTerm.termEndDate,
                  termName: newTermName,
                  termStartDate: oldTerm.termStartDate,
                );
                final tmp = globalState!.terms;
                tmp[currentTabIndex] = newTerm;

                await firestore.collection('global').doc('state').update({
                  'terms': tmp.map((t) => t.toJson()),
                });
                globalState = GlobalState.fromJson(
                  (await firestore.collection('global').doc('state').get())
                      .data()!,
                );

                await allocsColl
                    .doc(newTermName)
                    .set(
                      (allocationsCache.registry[newTermName] =
                              await allocationsCache.get(oldTerm.termName))
                          .data()!,
                    );
                allocationsCache.registry.remove(oldTerm.termName);

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
              await studentsCache.initAll();
              final allocs = {
                for (final cl in classesCache.registry.entries)
                  cl.key: {
                    for (final studentId in ClassData.fromJson(
                      cl.value.data()!,
                    ).studentIds)
                      if (!StudentData.fromJson(
                        (await studentsCache.get(studentId)).data()!,
                      ).withdrawn[cl.key]!)
                        studentId: -1,
                  },
              };

              await allocsColl.doc(termName).set(allocs);

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
          length: globalState == null ? 0 : globalState!.terms.length,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsetsGeometry.only(left: 40, right: 40),
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
                        const Spacer(),
                        SizedBox(
                          width: 230,
                          child: TextField(
                            controller: allocateAllSessionsController,
                            decoration: InputDecoration(
                              hint: Text(
                                'Allocate sessions for all',
                                style: body2.copyWith(
                                  color: AxisColors.blackPurple20.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AxisColors.lilacPurple20,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AxisColors.lilacPurple50.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        AxisButton.text(
                          label: 'Allocate',
                          isHighlighted: true,
                          onPressed: () async {
                            String msg;
                            if (int.tryParse(
                                  allocateAllSessionsController.text.trim(),
                                ) !=
                                null) {
                              msg = 'Allocated all sessions successfully!';
                              final int sc = int.parse(
                                allocateAllSessionsController.text.trim(),
                              );
                              final bool res = await showDialog(
                                context: context,
                                builder: (_) => ConfirmationDialog(
                                  confirmationMsg:
                                      "This action will allocate $sc sessions for every student visible in the current view (${visibleRows.length} students). Are you sure you want to continue?",
                                ),
                              );
                              final allocData = TermAllocation.fromJson(
                                (await allocationsCache.get(
                                  globalState!.terms[currentTabIndex].termName,
                                )).data()!,
                              );
                              if (res) {
                                final visibleIds = visibleRows.map((r) => r.$2);
                                for (final clEntry
                                    in allocData.sessions.entries) {
                                  final affectedKeys = clEntry.value.keys.where(
                                    (e) => visibleIds.contains(e),
                                  );
                                  for (final k in affectedKeys) {
                                    allocData.sessions[clEntry.key]![k] = sc;
                                  }
                                }

                                await allocsColl
                                    .doc(
                                      globalState!
                                          .terms[currentTabIndex]
                                          .termName,
                                    )
                                    .set(allocData.toJson());
                                allocationsCache.registry[globalState!
                                    .terms[currentTabIndex]
                                    .termName] = await allocsColl
                                    .doc(
                                      globalState!
                                          .terms[currentTabIndex]
                                          .termName,
                                    )
                                    .get();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(content: Text(msg)),
                                  );
                                }
                              } else {
                                msg = 'Action cancelled.';
                              }
                            } else {
                              msg = 'Error: Invalid input provided.';
                            }
                          },
                        ),
                      ],
                    ),
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
                    child: FutureBuilderTemplate(
                      future: () async {
                        return TermAllocation.fromJson(
                          (await allocationsCache.get(
                            globalState!.terms[currentTabIndex].termName,
                          )).data()!,
                        );
                      }(),
                      builder: (context, snapshot) => TabBarView(
                        key: ValueKey(
                          '${filterClassMenuController.text}-${filterStudentMenuController.text}-${snapshot.data!.sessions}',
                        ),
                        children: rebuildTabViews(snapshot.data!),
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

  List<Widget> rebuildTabViews(TermAllocation allocData) {
    tabViews.clear();
    for (int i = 0; i < globalState!.terms.length; i++) {
      tabViews.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FutureBuilderTemplate(
              future: () async {
                final List<DataRow> rows = [];
                for (final entry in classesCache.registry.entries) {
                  final cd = (await classesCache.get(
                    entry.key,
                  ));
                  final classData = ClassData.fromJson(
                    cd.data()!,
                  );
                  if (filterClassMenuController.text != 'None' &&
                      filterClassMenuController.text != classData.name) {
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
                  for (final stId in classData.studentIds) {
                    final sd = (await studentsCache.get(
                      stId,
                    ));
                    final studentData = StudentData.fromJson(
                      sd.data()!,
                    );
                    if (filterStudentMenuController.text != 'None' &&
                        filterStudentMenuController.text != studentData.name) {
                      continue;
                    }
                    if (studentData.withdrawn[cd.id]!) continue;
                    //  numEntriesAdded += 1;
                    visibleRows.add((sd, cd.id));

                    final String rowData =
                        allocData.sessions[cd.id]![sd.id] == -1
                        ? 'Unallocated'
                        : "${allocData.sessions[cd.id]![sd.id]}";
                    final rowKey = "${entry.key}-$stId-$rowData";

                    if (!controllers.containsKey(rowKey)) {
                      controllers[rowKey] = TextEditingController(
                        text: rowData,
                      );
                    }
                    final r = DataRow(
                      color: rowData != 'Unallocated'
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
                            final sd = await studentsCache.get(stId);
                            await showDialog(
                              context: context,
                              builder: (_) => StudentInfoDialog(
                                studentId: stId,
                                studentData: sd,
                                classIdToTeacherNameMap:
                                    classIdToTeacherNameMap,
                              ),
                            );
                          },
                        ),
                        DataCell(
                          TextField(
                            controller: controllers[rowKey]!,
                            onEditingComplete: () async {
                              final String msg;

                              final int? newInt = int.tryParse(
                                controllers[rowKey]!.text,
                              );
                              if (controllers[rowKey]!.text.isEmpty) {
                                msg = 'Action canclled.';
                                controllers[rowKey]!.text = rowData;
                              } else if (newInt != null) {
                                await allocsColl
                                    .doc(
                                      globalState!
                                          .terms[currentTabIndex]
                                          .termName,
                                    )
                                    .update({'${cd.id}.${sd.id}': newInt});
                                await allocationsCache.get(
                                  globalState!.terms[currentTabIndex].termName,
                                  bypassCache: true,
                                );

                                msg = 'Updated session count successfully!';

                                setState(() {});
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
                                controllers[rowKey]!.value.text,
                                style: body2.copyWith(
                                  color: AxisColors.blackPurple20,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AxisColors.lilacPurple20.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AxisColors.lilacPurple50.withValues(
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
                            controllers[rowKey]!.text == 'Unallocated'
                                ? ''
                                : "${int.parse(controllers[rowKey]!.text) - classData.attendance.entries.where(
                                        (entry) => monthKeyToTermIndex(globalState!, entry.key) == currentTabIndex && entry.value.containsKey(
                                              stId,
                                            ) && entry.value[stId]!.isPresent,
                                      ).length}",
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
                                      'Are you sure you would like to withdraw from class "${classData.name}"?',
                                ),
                              );
                              final String msg;
                              if (confirm) {
                                await withdrawStudentFromClass(
                                  studentId: stId,
                                  classId: (await classesCache.get(
                                    entry.key,
                                  )).id,
                                );
                                await classesCache.get(
                                  entry.key,
                                  bypassCache: true,
                                );
                                await studentsCache.get(
                                  stId,
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
                    );
                    rows.add(r);
                  }
                  if (rows.last.cells[1] == DataCell.empty) {
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
      );
    }
    return tabViews;
  }

  Widget createFilterMenu<T>(
    BuildContext context, {
    required TextEditingController controller,
    required List<DropdownMenuEntry<T>> entries,
  }) => DropdownMenu(
    leadingIcon: controller.value.text != 'None' ? Icon(Icons.check) : null,
    controller: controller,
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AxisColors.blackPurple30.withValues(alpha: 0.8),
        ),
      ),
      border: OutlineInputBorder(
        borderSide: BorderSide(
          color: AxisColors.blackPurple30.withValues(alpha: 0.8),
        ),
      ),
      contentPadding: EdgeInsets.only(left: 20),
    ),
    textStyle: body2,
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
