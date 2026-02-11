part of axis_dashboard;

class TermDetailsPage extends StatefulWidget {
  const TermDetailsPage({super.key});

  @override
  State<StatefulWidget> createState() => TermDetailsPageState();
}

class TermDetailsPageState extends State<TermDetailsPage> {
  String termName = '';
  GlobalState? globalState;
  bool showSessionAllocation = false;
  final shadowColl = firestore
      .collection('global')
      .doc('state')
      .collection('nextTermSessionAllocations');

  // Session Alloc State
  final GenericCache<DocumentSnapshot<JSON>> classesDataCache = GenericCache((
    classId,
  ) async {
    return (await firestore.collection('classes').doc(classId).get());
  });
  final GenericCache<DocumentSnapshot<JSON>> shadowDocsCache = GenericCache((
    studentId,
  ) async {
    return (await firestore
        .collection('global')
        .doc('state')
        .collection('nextTermSessionAllocations')
        .doc(studentId)
        .get());
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilderTemplate(
      future: () async {
        final gs = (globalState == null)
            ? globalState = GlobalState.fromJson(
                (await firestore.collection('global').doc('state').get())
                    .data()!,
              )
            : globalState;
        termName = "${DateTime.now().year} T${gs!.currentTermNum}";
        return gs;
      }(),
      builder: (context, snapshot) => Navbar(
        pageTitle: 'Term Details',
        actions: [
          if (globalState!.hasEndDateSet &&
              DateTime.now().isAfter(
                DateTime.fromMillisecondsSinceEpoch(
                  globalState!.currentTermEndDate,
                ).subtract(const Duration(days: 7)),
              ))
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child:
                  globalState!.hasEndDateSet &&
                      DateTime.now().isSameDayAs(
                        DateTime.fromMillisecondsSinceEpoch(
                          globalState!.currentTermEndDate,
                        ),
                      )
                  ? TextButton(
                      onPressed: () async {
                        final bool confirm = await showDialog(
                          context: context,
                          builder: (_) => ConfirmationDialog(
                            confirmationMsg:
                                'Are you sure you would like to end the current term?\nThis will take a snapshot of all attendance sheets and then reset them.',
                          ),
                        );
                        final String msg;
                        if (confirm) {
                          await ResetTermReportsOperation().executeInSequence(
                            termName,
                          );
                          msg = 'Current term has been ended!';
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
                      child: Text(
                        'End Current Term',
                        style: buttonLabel,
                      ),
                    )
                  : Text(
                      "${DateTime.fromMillisecondsSinceEpoch(
                        globalState!.currentTermEndDate,
                      ).difference(DateTime.now()).inDays} days to term end",
                      style: body2,
                    ),
            ),
        ],
        body: (context) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsetsGeometry.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              key: ValueKey(globalState!.currentTermEndDate),

              children: [
                const SizedBox(height: 30),
                if (globalState!.hasEndDateSet &&
                    DateTime.now().isSameDayAs(
                      DateTime.fromMillisecondsSinceEpoch(
                        globalState!.currentTermEndDate,
                      ),
                    )) ...[
                  Text(
                    'New Term Setup Required\nPlease update initial session allocations for students before logging attendance for the new term.',
                    style: body2,
                  ),
                  const SizedBox(height: 30),
                ],
                Text(
                  'Term Name',
                  style: heading3,
                ),
                Text(termName, style: body2),
                const SizedBox(height: 20),
                Text(
                  'Current Term Start Date',
                  style: heading3,
                ),
                Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    globalState!.currentTermStartDate,
                  ).toTimestampStringShort(),
                  style: body2,
                ),
                const SizedBox(height: 20),
                Text(
                  'Current Term End Date',
                  style: heading3,
                ),
                Text(
                  globalState!.hasEndDateSet
                      ? DateTime.fromMillisecondsSinceEpoch(
                          globalState!.currentTermEndDate,
                        ).toTimestampStringShort()
                      : 'No date set.',
                  style: body2,
                ),
                const SizedBox(height: 10),
                AxisNMButton(
                  label: globalState!.currentTermEndDate == 0
                      ? 'Set Date'
                      : 'Modify Date',
                  onPressed: () async {
                    final endDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    final bool confirm = await showDialog(
                      context: context,
                      builder: (_) => ConfirmationDialog(
                        confirmationMsg:
                            'Are you sure you want to adjust the term end date?',
                      ),
                    );
                    if (!confirm) return;
                    if (endDate != null) {
                      await firestore.collection('global').doc('state').update({
                        'currentTermEndDate': endDate.millisecondsSinceEpoch,
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
                        globalState = globalState = GlobalState.fromJson(
                          (await firestore
                                  .collection('global')
                                  .doc('state')
                                  .get())
                              .data()!,
                        );
                      }

                      setState(() {});
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'No date set',
                              style: body2,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 50),
                AxisButton.text(
                  width: 370,
                  label: 'Show Session Allocations For Next Term',
                  isHighlighted: true,
                  onPressed: () {
                    setState(() {
                      showSessionAllocation = !showSessionAllocation;
                    });
                  },
                ),
                const SizedBox(height: 30),
                if (showSessionAllocation)
                  FutureBuilderTemplate(
                    future: () async {
                      if (shadowDocsCache.registry.isEmpty) {
                        final shadowDocs = (await shadowColl.get()).docs;
                        if (shadowDocs.isEmpty) {
                          final query = (await firestore
                              .collection('users')
                              .where('role', isEqualTo: 'student')
                              .get());
                          for (final doc in query.docs) {
                            final shadowDoc = shadowColl.doc(doc.id);
                            final newData = StudentData.fromJson(doc.data());
                            for (final classEntry
                                in newData.initialSessionCount.entries) {
                              newData.initialSessionCount[classEntry.key] = -1;
                            }
                            await shadowDoc.set(newData.toJson());
                            shadowDocsCache.registry[shadowDoc.id] =
                                await shadowDoc.get();
                          }

                          setState(() {});
                        } else {
                          for (final doc in shadowDocs) {
                            shadowDocsCache.registry[doc.id] = doc;
                          }
                        }
                      }
                      return shadowDocsCache.registry;
                    }(),
                    builder: (context, snapshot) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        AxisCard(
                          header: 'Session Allocations',
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: null,
                          child: FutureBuilderTemplate(
                            future: () async {
                              final List<DataRow> rows = [];
                              for (final student
                                  in shadowDocsCache.registry.entries) {
                                final studentData = StudentData.fromJson(
                                  student.value.data()!,
                                );
                                rows.add(
                                  DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          studentData.name,
                                          style: body2,
                                        ),
                                      ),
                                      DataCell.empty,
                                      DataCell.empty,
                                      DataCell.empty,
                                    ],
                                  ),
                                );

                                for (final entry
                                    in studentData
                                        .initialSessionCount
                                        .entries) {
                                  final classData = ClassData.fromJson(
                                    (await classesDataCache.get(
                                      entry.key,
                                    )).data()!,
                                  );
                                  rows.add(
                                    DataRow(
                                      color: entry.value != -1
                                          ? null
                                          : WidgetStatePropertyAll(
                                              Colors.yellow.withValues(
                                                alpha: 0.1,
                                              ),
                                            ),
                                      cells: [
                                        DataCell.empty,
                                        DataCell(
                                          Text(
                                            classData.name,
                                            style: body2,
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            entry.value != -1
                                                ? '${entry.value}'
                                                : 'Not set',
                                            style: body2,
                                          ),
                                        ),
                                        DataCell(
                                          AxisNMButton(
                                            label: entry.value == -1
                                                ? 'Allocate sessions'
                                                : 'Update allocation',

                                            onPressed: () async {
                                              final RegisterForClassData data =
                                                  await showDialog(
                                                    context: context,
                                                    builder: (_) =>
                                                        RegisterForClassDialog(
                                                          classesDataCache:
                                                              classesDataCache,
                                                          fixedClassId:
                                                              entry.key,
                                                        ),
                                                  );
                                              final msg;
                                              if (data.sessionsCount == -1) {
                                                msg =
                                                    'Session allocation cancelled';
                                              } else {
                                                await shadowColl
                                                    .doc(student.key)
                                                    .update({
                                                      'initialSessionCount.${entry.key}':
                                                          data.sessionsCount,
                                                    });
                                                await removeAndRefresh(
                                                  student.key,
                                                );

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
                                  child: DataTable(
                                    dataRowMinHeight: 60,
                                    dataRowMaxHeight: 80,
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
                                          'Initial Session Count',
                                          style: body2.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(label: const SizedBox()),
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
      ),
    );
  }

  Future<void> removeAndRefresh(String studentId) async {
    shadowDocsCache.registry.remove(studentId);
    await shadowDocsCache.get(studentId);
  }
}
