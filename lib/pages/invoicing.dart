part of axis_dashboard;

class InvoicingPage extends StatefulWidget {
  const InvoicingPage({super.key});

  @override
  State<StatefulWidget> createState() => InvoicingPageState();
}

class InvoicingPageState extends State<InvoicingPage> {
  int currentTabIndex = 0;
  final GenericCache<DocumentSnapshot<JSON>> studentCache = GenericCache(
    (studentId) async =>
        await firestore.collection('users').doc(studentId).get(),
  );
  final GenericCache<DocumentSnapshot<JSON>> teachersCache = GenericCache(
    (teacherId) async =>
        await firestore.collection('users').doc(teacherId).get(),
  );
  final GenericCache<DocumentSnapshot<JSON>> classesCache = GenericCache(
    (classId) async => await firestore.collection('classes').doc(classId).get(),
  );
  GlobalState? globalState;
  final GenericCache<DocumentSnapshot<JSON>> studentInvoicesCache =
      GenericCache(
        (invoiceId) async => firestore
            .collection('global')
            .doc('archives')
            .collection('invoices')
            .doc(invoiceId)
            .get(),
      );
  final GenericCache<DocumentSnapshot<JSON>> teachersInvoiceCache =
      GenericCache(
        (invoiceId) async => firestore
            .collection('global')
            .doc('archives')
            .collection('invoices')
            .doc(invoiceId)
            .get(),
      );

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Invoicing',
      actions: [
        AxisButton.text(
          label: 'Refresh Invoices',
          onPressed: () async {
            if (currentTabIndex == 0) {
              for (final studentEntry in studentCache.registry.entries) {
                final studentData = StudentData.fromJson(
                  studentEntry.value.data()!,
                );

                for (int t = 0; t < studentData.sessionCounts.length; t++) {
                  DocumentSnapshot<JSON>? oldInvoiceSnapshot;
                  StudentInvoiceData? oldInvoiceData;
                  if (studentData.invoiceIds.isNotEmpty &&
                      studentData.invoiceIds[t] != null) {
                    oldInvoiceSnapshot = (await firestore
                        .collection('global')
                        .doc('archives')
                        .collection('invoices')
                        .doc(studentData.invoiceIds[t])
                        .get());
                    oldInvoiceData = StudentInvoiceData.fromJson(
                      oldInvoiceSnapshot.data()!,
                    );
                  }
                  final List<
                    ({double amt, String desc, double qty, double rate})
                  >
                  entries = [];
                  bool? invoiceIsDiff = oldInvoiceData == null ? null : false;
                  int classNum = 0;
                  int entryCounter = 0;
                  for (final entry in studentData.sessionCounts[t].entries) {
                    classNum += 1;
                    final double rate = classNum >= 3 ? (95 / 2) : 95.00;
                    final newEntry = (
                      amt: rate * entry.value,
                      desc: ClassData.fromJson(
                        (await classesCache.get(entry.key)).data()!,
                      ).name,
                      qty: entry.value as double,
                      rate: rate,
                    );
                    if (oldInvoiceData != null) {
                      final oldEntry = oldInvoiceData.entries[entryCounter];
                      if (oldEntry.amt != newEntry.amt ||
                          oldEntry.desc != newEntry.desc ||
                          oldEntry.qty != newEntry.qty ||
                          oldEntry.rate != newEntry.rate) {
                        invoiceIsDiff = true;
                      }
                    }
                    entries.add(newEntry);
                    entryCounter += 1;
                  }
                  if (invoiceIsDiff != null && !invoiceIsDiff) continue;

                  final docRef = firestore
                      .collection('global')
                      .doc('archives')
                      .collection('invoices')
                      .doc();
                  final newInvoice = StudentInvoiceData(
                    invoiceDateFormatted: DateTime.now()
                        .toTimestampStringShort(),
                    address: 'studentData.address',
                    amtPayable: entries.fold((0), (a, b) => a + b.amt),
                    dueDateFormatted: DateTime.now()
                        .add(const Duration(days: 7))
                        .toTimestampStringShort(),
                    entries: entries,
                    invoiceId: docRef.id,
                    parentName: studentData.parentName,
                    studentName: studentData.name,
                    terms: 'Custom',
                  );

                  if (invoiceIsDiff != null && invoiceIsDiff) {
                    print('Updating invoice for ${studentData.name}');
                  } else {
                    print(
                      'Creating invoice for ${studentData.name}, Term #${t + 1}',
                    );
                  }
                  await docRef.set(newInvoice.toJson());
                  final List<String?> newInvIds = studentData.invoiceIds;
                  newInvIds[t] = docRef.id;
                  await firestore
                      .collection('users')
                      .doc(studentEntry.key)
                      .update(
                        StudentData(
                          role: studentData.role,
                          name: studentData.name,
                          email: studentData.email,
                          invoiceIds: newInvIds,
                          studentContactNo: studentData.studentContactNo,
                          parentContactNo: studentData.parentContactNo,
                          parentName: studentData.parentName,
                          sessionCounts: studentData.sessionCounts,
                        ).toJson(),
                      );
                }
              }
            } else {
              /* 
              for (final teacherEntry in teachersCache.registry.entries) {
                final teacherData = TeacherData.fromJson(
                  teacherEntry.value.data()!,
                );
                Map<int, int> numSessionsForMonths = {};
                for (int i = 0; i < teacherData.classIds.length; i++) {
                  final String clId = teacherData.classIds[i];
                  final classData = ClassData.fromJson(
                    (await classesCache.get(clId)).data()!,
                  );

                  for (final attEntry in classData.attendance.entries) {
                    final List<
                      ({double amt, String desc, double qty, double rate})
                    >
                    entries = [];
                    int monthIndex =
                        (DateTime.parse(
                              attEntry.key,
                            ).difference(DateTime(2026, 01, 01)).inDays %
                            30) -
                        1;

                    if (!numSessionsForMonths.containsKey(monthIndex)) {
                      numSessionsForMonths[monthIndex] = 0;
                    } else {
                      numSessionsForMonths[monthIndex];
                    }

                    final newInvoice = TeacherInvoiceData(
                      invoiceDateFormatted: DateTime.now()
                          .toTimestampStringShort(),
                      address: 'studentData.address',
                      amtDue: entries.fold((0), (a, b) => a + b.amt),
                      paidDateFormatted: 'PENDING',
                      entries: entries,
                      invoiceId: 'docRef.id',
                      teacherName: teacherData.name,
                      adminName: TeacherData.fromJson(
                        (await firestore
                                .collection('users')
                                .doc(auth.currentUser!.uid)
                                .get())
                            .data()!,
                      ).name,
                      terms: 'Custom',
                    );

                    await docRef.set(newInvoice.toJson());
                    final List<String?> newInvIds = studentData.invoiceIds;
                    newInvIds[t] = docRef.id;
                    await firestore
                        .collection('users')
                        .doc(teacherEntry.key)
                        .update(
                          StudentData(
                            role: studentData.role,
                            name: studentData.name,
                            email: studentData.email,
                            invoiceIds: newInvIds,
                            studentContactNo: studentData.studentContactNo,
                            parentContactNo: studentData.parentContactNo,
                            parentName: studentData.parentName,
                            sessionCounts: studentData.sessionCounts,
                          ).toJson(),
                        );
                  }
                }
              }
             */
            }
            setState(() {});
          },
        ),
      ],
      body: (context) => DefaultTabController(
        length: 2,
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              TabBar(
                onTap: (index) {
                  currentTabIndex = index;
                  setState(() {});
                },
                tabs: const [
                  Text('Students'),
                  Text('Teachers'),
                ],
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height - 190,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: TabBarView(
                    children: [
                      generateTabView('student'),
                      generateTabView('teacher'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget generateTabView(String viewType) {
    return FutureBuilderTemplate(
      future: () async {
        globalState ??= GlobalState.fromJson(
          (await firestore.collection('global').doc('state').get()).data()!,
        );
        if (viewType == 'student') {
          if (!studentCache._hasInitAll) {
            await studentCache.initAll(
              query: firestore
                  .collection('users')
                  .where('role', isEqualTo: 'student'),
            );
          }
          if (!studentInvoicesCache._hasInitAll) {
            await studentInvoicesCache.initAll(
              query: firestore
                  .collection('global')
                  .doc('archives')
                  .collection('invoices')
                  .where('invoiceType', isEqualTo: 'student'),
            );
          }
          return studentCache.registry;
        } else {
          if (!teachersCache._hasInitAll) {
            await teachersCache.initAll(
              query: firestore
                  .collection('users')
                  .where('role', isEqualTo: 'teacher'),
            );
          }
          if (!teachersInvoiceCache._hasInitAll) {
            await teachersInvoiceCache.initAll(
              query: firestore
                  .collection('global')
                  .doc('archives')
                  .collection('invoices')
                  .where('invoiceType', isEqualTo: 'teacher'),
            );
          }
          return teachersCache.registry;
        }
      }(),
      builder: (context, _) => DataTable(
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
          for (final term in globalState!.terms)
            DataColumn(
              label: Text(
                term.termName,
                style: body2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        rows: [
          if (viewType == 'student')
            for (final student in studentCache.registry.entries)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      StudentData.fromJson(
                        student.value.data()!,
                      ).name,
                      style: body2,
                    ),
                  ),
                  ...generateCellsForInvoices(
                    studentData: StudentData.fromJson(student.value.data()!),
                  ),
                ],
              ),
          if (viewType == 'teacher')
            for (final teacher in teachersCache.registry.entries)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      TeacherData.fromJson(
                        teacher.value.data()!,
                      ).name,
                      style: body2,
                    ),
                  ),
                  ...generateCellsForInvoices(
                    teacherData: TeacherData.fromJson(teacher.value.data()!),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  List<DataCell> generateCellsForInvoices({
    StudentData? studentData,
    TeacherData? teacherData,
  }) {
    final List<DataCell> res = [];
    for (int i = 0; i < globalState!.terms.length; i++) {
      res.add(
        DataCell(
          studentData != null
              ? (studentData.invoiceIds.isNotEmpty &&
                        studentData.invoiceIds[i] != null
                    ? FutureBuilderTemplate(
                        future: () async {
                          return StudentInvoiceData.fromJson(
                            (await firestore
                                    .collection('global')
                                    .doc('archives')
                                    .collection('invoices')
                                    .doc(studentData.invoiceIds[i])
                                    .get())
                                .data()!,
                          ).amtPayable;
                        }(),
                        builder: (_, snapshot) => SizedBox(
                          width: 200,
                          height: 80,
                          child: Row(
                            children: [
                              if (studentData.invoiceIds.isNotEmpty &&
                                  studentData.invoiceIds[i] != null)
                                AxisButton(
                                  width: 60,
                                  child: Icon(Icons.edit),
                                  onPressed: () async {
                                    final studentInvData =
                                        StudentInvoiceData.fromJson(
                                          (await firestore
                                                  .collection('global')
                                                  .doc('archives')
                                                  .collection('invoices')
                                                  .doc(
                                                    studentData.invoiceIds[i],
                                                  )
                                                  .get())
                                              .data()!,
                                        );

                                    if (context.mounted) {
                                      await showDialog(
                                        context: context,
                                        builder: (_) => EditableInvoiceDialog(
                                          studentInvoiceData: studentInvData,
                                          teacherInvoiceData: null,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              const SizedBox(width: 10),
                              Text(
                                "\$${snapshot.data!.toStringAsFixed(2)}",
                                style: body2,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Text(''))
              : Text('T'),
          /* (teacherData!.invoiceIds.containsKey(i) ? 'Y' : '')            style: body2.copyWith(
              fontWeight: FontWeight.bold,
            ), */
          onTap: (studentData == null && teacherData == null)
              ? null
              : () async {
                  final studentInvData = studentData != null
                      ? StudentInvoiceData.fromJson(
                          (await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(studentData.invoiceIds[i])
                                  .get())
                              .data()!,
                        )
                      : null;
                  final teacherInvData = teacherData != null
                      ? TeacherInvoiceData.fromJson(
                          (await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(teacherData.invoiceIds[i])
                                  .get())
                              .data()!,
                        )
                      : null;
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (_) => Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: InvoiceWidget(
                            studentInvoiceData: studentInvData,
                            teacherInvoiceData: teacherInvData,
                            total:
                                studentInvData?.amtPayable ??
                                teacherInvData!.amtDue,
                          ),
                        ),
                      ),
                    );
                  }
                },
        ),
      );
    }
    return res;
  }
}
