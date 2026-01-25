part of axis_dashboard;

class TermDetailsPage extends StatefulWidget {
  const TermDetailsPage({super.key});

  @override
  State<StatefulWidget> createState() => TermDetailsPageState();
}

class TermDetailsPageState extends State<TermDetailsPage> {
  GlobalState? globalState;
  bool showSessionAllocation = false;
  final shadowColl = firestore
      .collection('global')
      .doc('state')
      .collection('nextTermSessionAllocations');

  // Session Alloc State
  DocumentSnapshot<JSON>? currentStudent;
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
        return (globalState == null)
            ? globalState = GlobalState.fromJson(
                (await firestore.collection('global').doc('state').get())
                    .data()!,
              )
            : globalState;
      }(),
      builder: (context, snapshot) => Navbar(
        pageTitle:
            'Term Details (${DateTime.now().year} T${globalState!.currentTermNum})',
        actions: [
          if (globalState!.hasEndDateSet &&
              DateTime.now().isAfter(
                DateTime.fromMillisecondsSinceEpoch(
                  globalState!.currentTermEndDate,
                ).subtract(const Duration(days: 7)),
              ))
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                "${DateTime.fromMillisecondsSinceEpoch(
                  globalState!.currentTermEndDate,
                ).difference(DateTime.now()).inDays} days to term end",
              ),
            ),
        ],
        body: (context) => SingleChildScrollView(
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
                const Text(
                  'New Term Setup Required\nPlease update initial session allocations for students before logging attendance for the new term.',
                ),
                const SizedBox(height: 30),
              ],
              Text(
                'Current Term Start Date:\n${DateTime.fromMillisecondsSinceEpoch(globalState!.currentTermStartDate).toTimestampStringShort()}',
              ),
              const SizedBox(height: 20),
              Text(
                'Current Term End Date: ${globalState!.hasEndDateSet ? DateTime.fromMillisecondsSinceEpoch(globalState!.currentTermEndDate).toTimestampStringShort() : 'No date set.'}',
              ),
              TextButton(
                onPressed: () async {
                  final endDate = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (endDate != null) {
                    await firestore.collection('global').doc('state').update({
                      'currentTermEndDate': endDate.millisecondsSinceEpoch,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text('Term end date set successfully!'),
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
                          content: Text('No date set'),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  globalState!.currentTermEndDate == 0
                      ? 'Set Date'
                      : 'Modify Date',
                ),
              ),
              const SizedBox(height: 50),
              const Text('Show Session Allocations For Next Term'),
              const SizedBox(height: 10),
              Switch(
                value: showSessionAllocation,
                onChanged: (newVal) => setState(() {
                  showSessionAllocation = newVal;
                }),
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
                      DropdownMenu(
                        initialSelection: currentStudent ??=
                            shadowDocsCache.registry.values.first,
                        onSelected: (value) => setState(() {
                          if (value != null) currentStudent = value;
                        }),
                        dropdownMenuEntries: [
                          for (final student in shadowDocsCache.registry.values)
                            DropdownMenuEntry(
                              value: student,
                              label: StudentData.fromJson(student.data()!).name,
                            ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text('Session Allocations'),
                      const SizedBox(height: 10),
                      if (currentStudent != null)
                        FutureBuilderTemplate(
                          key: ValueKey(currentStudent!.id),
                          future: () async {
                            final List<DataRow> rows = [];
                            for (final entry in StudentData.fromJson(
                              currentStudent!.data()!,
                            ).initialSessionCount.entries) {
                              final cd = ClassData.fromJson(
                                (await classesDataCache.get(entry.key)).data()!,
                              );

                              rows.add(
                                DataRow(
                                  cells: [
                                    DataCell(Text(cd.name)),
                                    DataCell(
                                      Text(
                                        entry.value != -1
                                            ? '${entry.value}'
                                            : 'Not set',
                                      ),
                                    ),
                                    DataCell(
                                      TextButton(
                                        onPressed: () async {
                                          final RegisterForClassData data =
                                              await showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    RegisterForClassDialog(
                                                      classesDataCache:
                                                          classesDataCache,
                                                      fixedClassId: entry.key,
                                                    ),
                                              );
                                          final msg;
                                          if (data.sessionsCount == -1) {
                                            msg =
                                                'Session allocation cancelled';
                                          } else {
                                            await shadowColl
                                                .doc(currentStudent!.id)
                                                .update({
                                                  'initialSessionCount.${entry.key}':
                                                      data.sessionsCount,
                                                });
                                            await refreshStudentData();

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
                                        child: Text(
                                          entry.value == -1
                                              ? 'Allocate sessions'
                                              : 'Update allocation',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return rows;
                          }(),
                          builder: (context, snapshot) => DataTable(
                            columns: [
                              DataColumn(label: Text('Class')),
                              DataColumn(label: Text('Initial Session Count')),
                              DataColumn(label: const SizedBox()),
                            ],
                            rows: snapshot.data ?? const [],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> refreshStudentData() async {
    shadowDocsCache.registry.remove(currentStudent!.id);
    await shadowDocsCache.get(currentStudent!.id);
  }
}
