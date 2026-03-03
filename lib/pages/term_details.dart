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
  final Map<String, TextEditingController> controllers = {};
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
        await classesCache.initAll(firestore.collection('classes'));
        termNameController.text = globalState!.terms[currentTabIndex].termName;
        return globalState;
      }(),

      builder: (context, snapshot) => Navbar(
        pageTitle: 'Term Details',
        actions: [
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
                        Duration(days: 30).inMilliseconds,
                    termName: termName,
                    termStartDate:
                        globalState!.terms.last.termEndDate +
                        Duration(minutes: 1).inMilliseconds,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TabBar(
                  isScrollable: true,
                  key: ValueKey(
                    globalState!.terms.map((t) => t.termName).join('-'),
                  ),
                  onTap: (index) {
                    currentTabIndex = index;
                    termNameController.text =
                        globalState!.terms[index].termName;
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
                  height: MediaQuery.of(context).size.height - 130,
                  child: Center(
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 30),
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
                                      rows.add(
                                        DataRow(
                                          color: WidgetStatePropertyAll(
                                            AxisColors.blackPurple20.withValues(
                                              alpha: 0.14,
                                            ),
                                          ),
                                          cells: [
                                            DataCell(
                                              Text(
                                                classData.name,
                                                style: body2,
                                              ),
                                            ),
                                            DataCell.empty,
                                          ],
                                        ),
                                      );

                                      for (final studentEntry
                                          in entry.value.entries) {
                                        final studentData =
                                            StudentData.fromJson(
                                              (await studentsCache.get(
                                                studentEntry.key,
                                              )).data()!,
                                            );
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
                                              /*   DataCell(
                                              AxisNMButton(
                                                label: studentEntry.value == -1
                                                    ? 'Allocate sessions'
                                                    : 'Update allocation',

                                                onPressed: () async {
                                                  final RegisterForClassData
                                                  data = await showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        RegisterForClassDialog(
                                                          classesDataCache:
                                                              classesCache,
                                                          fixedClassId:
                                                              entry.key,
                                                        ),
                                                  );
                                                  final msg;
                                                  if (data.sessionsCount ==
                                                      -1) {
                                                    msg =
                                                        'Session allocation cancelled';
                                                  } else {
                                                    await firestore
                                                        .collection('global')
                                                        .doc('state')
                                                        .collection(
                                                          'allocations',
                                                        )
                                                        .doc(term.termName)
                                                        .update({
                                                          '${data.classId}.${studentEntry.key}':
                                                              data.sessionsCount,
                                                        });
                                                    /*  await removeAnd(
                                                      student.key,
                                                    ); */

                                                    msg =
                                                        'Session allocations updated successfully!';
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

                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                           */
                                            ],
                                          ),
                                        );
                                      }
                                    }

                                    return rows;
                                  }(),
                                  builder: (context, snapshot) =>
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Center(
                                          child: DataTable(
                                            dataRowMinHeight: 60,
                                            dataRowMaxHeight: 80,
                                            columns: [
                                              DataColumn(
                                                columnWidth: FixedColumnWidth(
                                                  240,
                                                ),
                                                label: Text(
                                                  'Name',
                                                  style: body2.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                              DataColumn(
                                                label: Text(
                                                  'Allocated Session Count',
                                                  style: body2.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              //   DataColumn(label: const SizedBox()),
                                            ],
                                            rows: snapshot.data ?? const [],
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
}
