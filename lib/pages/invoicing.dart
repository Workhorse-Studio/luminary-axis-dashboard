part of axis_dashboard;

class InvoicingPage extends StatefulWidget {
  const InvoicingPage({super.key});

  @override
  State<StatefulWidget> createState() => InvoicingPageState();
}

class InvoicingPageState extends State<InvoicingPage> {
  int currentTabIndex = 0;
  final Map<String, pdf.ExportFrame> frames = {};
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

  final Map<String, Map<String, Map<String, int>>> sessionsMap = {};

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Billings',
      actions: [
        AxisButton.text(
          icon: Icons.refresh,
          label: 'Refresh Invoices',
          onPressed: () async {
            int numUpdated = 0;

            if (currentTabIndex == 0) {
              await studentAttendanceStore.ensureInit(
                globalState: globalState!,
                classesCache: classesCache,
                studentCache: studentCache,
              );

              /* for (final studentEntry in studentCache.registry.entries) {
                DocumentSnapshot<JSON>? oldInvoiceSnapshot;
                StudentInvoiceData? oldInvoiceData;
                final studentData = StudentData.fromJson(
                  studentEntry.value.data()!,
                );
                if (studentData.invoiceIds.isNotEmpty &&
                    studentData.invoiceIds[] != null) {
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
                
                bool? invoiceIsDiff = oldInvoiceData == null ? null : false;
                int classNum = 0;
              } */

              /* for (final studentEntry in studentCache.registry.entries) {
                final studentData = StudentData.fromJson(
                  studentEntry.value.data()!,
                );

                for (int t = 0; t < globalState!.terms.length; t++) {
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
                  final List<({double amt, String desc, int qty, double rate})>
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
                      qty: entry.value,
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
                  numUpdated += 1;
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
                    invoiceStatus: InvoiceStatus.ready,
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
                        ).toJson(),
                      );
                }
              }
            */
            } else {
              await fetchUpdatedTeacherInvoices(forceAll: true);
            }

            setState(() {});
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(content: Text('$numUpdated invoices were updated.')),
              );
            }
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
                indicatorColor: AxisColors.lilacPurple20,
                tabs: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Students',
                      style: heading3.copyWith(
                        color: currentTabIndex == 0
                            ? AxisColors.lilacPurple20
                            : AxisColors.lilacPurple50,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Teachers',
                      style: heading3.copyWith(
                        color: currentTabIndex == 1
                            ? AxisColors.lilacPurple20
                            : AxisColors.lilacPurple50,
                      ),
                    ),
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
        if (viewType == 'student') {
          globalState ??= GlobalState.fromJson(
            (await firestore.collection('global').doc('state').get()).data()!,
          );
          await studentCache.initAll(
            query: firestore
                .collection('users')
                .where('role', isEqualTo: 'student'),
          );
          await studentInvoicesCache.initAll(
            query: firestore
                .collection('global')
                .doc('archives')
                .collection('invoices')
                .where('invoiceType', isEqualTo: 'student'),
          );
          await studentAttendanceStore.ensureInit(
            globalState: globalState!,
            classesCache: classesCache,
            studentCache: studentCache,
          );
          return studentCache.registry;
        } else {
          await classesCache.initAll(
            collection: firestore.collection('classes'),
          );
          await teachersCache.initAll(
            query: firestore
                .collection('users')
                .where('role', isEqualTo: 'teacher'),
          );
          await teachersInvoiceCache.initAll(
            query: firestore
                .collection('global')
                .doc('archives')
                .collection('invoices')
                .where('invoiceType', isEqualTo: 'teacher'),
          );
          if (sessionsMap.isEmpty) await fetchUpdatedTeacherInvoices();
          return teachersCache.registry;
        }
      }(),
      builder: (context, _) => DataTable2(
        fixedLeftColumns: 1,
        columns: viewType == 'student'
            ? [
                DataColumn2(
                  fixedWidth: 160,
                  label: Text(
                    'Name',
                    style: body2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: body2.fontSize! + 8,
                    ),
                  ),
                ),
                for (final term in globalState!.terms)
                  DataColumn2(
                    label: Center(
                      child: Text(
                        term.termName,
                        style: body2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: body2.fontSize! + 8,
                        ),
                      ),
                    ),
                  ),
              ]
            : [
                DataColumn2(
                  fixedWidth: 160,
                  label: Text(
                    'Name',
                    style: body2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: body2.fontSize! + 8,
                    ),
                  ),
                ),
                for (final monthId in generateMonthIds())
                  DataColumn2(
                    minWidth: 420,
                    label: Center(
                      child: Text(
                        "${monthId.split('-')[0]}/${monthId.split('-')[1].substring(2)}",
                        style: body2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: body2.fontSize! + 8,
                        ),
                      ),
                    ),
                  ),
              ],
        rows: [
          if (viewType == 'student')
            for (final student in studentCache.registry.entries)
              DataRow2(
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
              DataRow2(
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
                    teacherData: teacher.value,
                  ),
                ],
              ),
        ],
      ),
    );
  }

  List<String> generateMonthIds() {
    int currentYear = DateTime.now().year;
    int startYear = 2026;
    final List<String> res = [];
    void generateForYear(int year) {
      for (int i = 1; i < 13; i++) {
        res.add("$i-$year");
      }
    }

    for (int i = startYear; i <= currentYear; i++) {
      generateForYear(i);
    }
    return res;
  }

  List<DataCell> generateCellsForInvoices({
    StudentData? studentData,
    DocumentSnapshot<JSON>? teacherData,
  }) {
    final List<DataCell> res = [];
    if (studentData != null) {
      for (int i = 0; i < globalState!.terms.length; i++) {
        res.add(
          DataCell(
            studentData.invoiceIds.isNotEmpty &&
                    studentData.invoiceIds[i] != null
                ? FutureBuilderTemplate(
                    future: () async {
                      return (
                        amt: StudentInvoiceData.fromJson(
                          (await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(studentData.invoiceIds[i])
                                  .get())
                              .data()!,
                        ).amtPayable,
                        invoice: StudentInvoiceData.fromJson(
                          (await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(
                                    studentData.invoiceIds[i],
                                  )
                                  .get())
                              .data()!,
                        ),
                      );
                    }(),
                    builder: (_, snapshot) => Center(
                      child: SizedBox(
                        width: 380,
                        height: 80,
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            Text(
                              "\$${snapshot.data!.amt.toStringAsFixed(2)}",
                              style: body2,
                            ),
                            const Spacer(),
                            if (studentData.invoiceIds.isNotEmpty &&
                                studentData.invoiceIds[i] != null) ...[
                              AxisButton.text(
                                width: 100,
                                icon: Icons.edit,
                                label: 'Edit',
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

                              AxisButton(
                                width: 80,
                                height: 30,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: (switch (snapshot
                                        .data!
                                        .invoice
                                        .invoiceStatus) {
                                      InvoiceStatus.ready => Colors.amber,
                                      InvoiceStatus.paid => Colors.green,
                                      InvoiceStatus.missed => Colors.red,
                                      InvoiceStatus.sent => Colors.blue,
                                    }).withValues(alpha: 0.4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      snapshot.data!.invoice.invoiceStatus.name,
                                      style: body2.copyWith(
                                        color: AxisColors.blackPurple50,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AxisButton.text(
                                width: 100,
                                icon: Icons.send,
                                label: 'Send',
                                onPressed: () async {
                                  final ExportDelegate exportDelegate =
                                      ExportDelegate();
                                  frames[snapshot
                                      .data!
                                      .invoice
                                      .invoiceId] = pdf.ExportFrame(
                                    frameId: snapshot.data!.invoice.invoiceId,
                                    exportDelegate: exportDelegate,
                                    child: InvoiceWidget(
                                      studentInvoiceData:
                                          snapshot.data!.invoice,
                                      teacherInvoiceData: null,
                                      total: snapshot.data!.invoice.amtPayable,
                                    ),
                                  );

                                  await WidgetsBinding.instance.endOfFrame;

                                  // export the frame to a PDF Document
                                  final pdfDoc = await exportDelegate
                                      .exportToPdfDocument(
                                        snapshot.data!.invoice.invoiceId,
                                      );
                                  final file = web.File(
                                    [
                                      (await pdfDoc.document.save()).buffer.toJS
                                          as JSAny,
                                    ].toJS,
                                    'invoice.pdf',
                                  );
                                  final message = Message()
                                    ..from = Address(
                                      'siddharth.chitikela@gmail.com',
                                    )
                                    ..recipients = [
                                      'siddharth.personal0@gmail.com',
                                    ]
                                    ..subject = 'Hello!'
                                    ..text = 'Test 1\n2\n3'
                                  /* ..attachments.add(
                                      FileAttachment(file),
                                    ) */
                                  ;

                                  try {
                                    print(appPassword.length);
                                    // Send the message
                                    final sendReport = await send(
                                      message,
                                      gmail(
                                        'siddharth.chitikela@gmail.com',
                                        appPassword,
                                      ),
                                    );
                                    print(
                                      'Message sent: ' + sendReport.toString(),
                                    );
                                  } on MailerException catch (e) {
                                    print(
                                      'Message not sent. \n${e.toString()}',
                                    );
                                    for (var problem in e.problems) {
                                      print(
                                        'Problem: ${problem.code}: ${problem.msg}',
                                      );
                                    }
                                  }
                                  /* final blob = web.Blob(
                                    [
                                      (await pdf.document.save()).buffer.toJS
                                          as JSAny,
                                    ].toJS,
                                    web.BlobPropertyBag(
                                      type: 'application/pdf',
                                    ),
                                  );
                                  final url = web.URL.createObjectURL(blob);
                                  //web.document.createElement('a') as
                                  final anchor = web.HTMLAnchorElement()
                                    ..href = url
                                    ..style.display = 'none'
                                    ..download = 'invoice.pdf';
                                  web.document.body!.append(anchor);
                                  anchor.click(); */
                                },
                              ),
                              Offstage(
                                child: frames[snapshot.data!.invoice.invoiceId],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                : Text(''),
            onTap: () async {
              final studentInvData = StudentInvoiceData.fromJson(
                (await firestore
                        .collection('global')
                        .doc('archives')
                        .collection('invoices')
                        .doc(studentData.invoiceIds[i])
                        .get())
                    .data()!,
              );

              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (_) => Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.height * 0.85,
                      child: InvoiceWidget(
                        studentInvoiceData: studentInvData,
                        teacherInvoiceData: null,
                        total: studentInvData.amtPayable,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        );
      }
    } else {
      final mIds = generateMonthIds();
      for (final String monthId in mIds) {
        res.add(
          DataCell(
            teacherData != null &&
                    sessionsMap.isNotEmpty &&
                    sessionsMap[teacherData.id]!.containsKey(monthId)
                ? Center(
                    child: SizedBox(
                      width: 180,
                      height: 80,
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          RichText(
                            text: TextSpan(
                              text:
                                  "${sessionsMap[teacherData.id]![monthId]!.values.fold(0, (a, b) => a + b)} sessions\n",
                              style: body2.copyWith(
                                fontSize: body2.fontSize! - 4,
                                color: body2.color?.withValues(alpha: 0.7),
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      "\$${TeacherPayout(classToNumSessionsMap: sessionsMap[teacherData.id]![monthId]!).calculateFinalPayout(sessionsMap[teacherData.id]![monthId]!.values.fold(0, (a, b) => a + b)).toStringAsFixed(2)}",
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          AxisButton.text(
                            width: 105,
                            icon: Icons.send,
                            label: 'Send',
                            onPressed: () async {},
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(''),
            onTap: () async {
              /* final studentInvData = StudentInvoiceData.fromJson(
                (await firestore
                        .collection('global')
                        .doc('archives')
                        .collection('invoices')
                        .doc(studentData.invoiceIds[i])
                        .get())
                    .data()!,
              );
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
                        total: studentInvData.amtPayable,
                      ),
                    ),
                  ),
                );
              } */
            },
          ),
        );
      }
    }

    return res;
  }

  Future<void> fetchUpdatedTeacherInvoices({bool forceAll = false}) async {
    final Map<String, Map<String, Map<String, int>>> newSessions = {};
    final mIds = generateMonthIds();
    for (final teacherEntry in teachersCache.registry.entries) {
      final teacherData = TeacherData.fromJson(
        teacherEntry.value.data()!,
      );
      newSessions[teacherEntry.key] = {for (final m in mIds) m: {}};
      for (int i = 0; i < teacherData.classIds.length; i++) {
        final String clId = teacherData.classIds[i];
        final classData = ClassData.fromJson(
          (await classesCache.get(clId)).data()!,
        );

        for (final attEntry in classData.attendance.entries) {
          if (attEntry.value.isEmpty) continue;
          final String monthId = attEntry.key.split('-').sublist(1).join('-');
          if (!newSessions[teacherEntry.key]![monthId]!.containsKey(clId)) {
            newSessions[teacherEntry.key]![monthId]![clId] = 0;
          }
          newSessions[teacherEntry.key]![monthId]![clId] =
              newSessions[teacherEntry.key]![monthId]![clId]! +
              attEntry.value.values.where((a) => a.isPresent).length;
        }
      }
    }
    sessionsMap
      ..clear()
      ..addAll(newSessions);
  }
}
