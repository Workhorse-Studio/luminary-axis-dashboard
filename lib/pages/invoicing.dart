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

  Widget? shownFrame;

  int year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Billings',
      actions: [
        if (currentTabIndex == 1) ...[
          AxisButton(
            width: 60,
            height: 60,
            onPressed: () => setState(() {
              year -= 1;
            }),
            child: Icon(
              Icons.chevron_left,
              size: 40,
            ),
          ),
          Text(
            "$year",
            style: heading3,
          ),
          AxisButton(
            width: 60,
            height: 60,
            onPressed: () => setState(() {
              year += 1;
            }),
            child: Icon(
              Icons.chevron_right,
              size: 40,
            ),
          ),
        ],
        const SizedBox(width: 40),
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

              await studentAttendanceStore.run(
                globalState: globalState!,
                classesCache: classesCache,
                studentCache: studentCache,
              );
              setState(() {});
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
              const SizedBox(height: 80),
              if (shownFrame != null) shownFrame!,
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
                    minWidth: 450,
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
                    minWidth: 230,
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
                    studentData: student.value,
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
    final List<String> res = [];
    void generateForYear(int year) {
      for (int i = 1; i < 13; i++) {
        res.add("$i-$year");
      }
    }

    generateForYear(year);

    return res;
  }

  List<DataCell> generateCellsForInvoices({
    DocumentSnapshot<JSON>? studentData,
    DocumentSnapshot<JSON>? teacherData,
  }) {
    final List<DataCell> res = [];
    if (studentData != null) {
      for (int i = 0; i < globalState!.terms.length; i++) {
        res.add(
          DataCell(
            Center(
              child: SizedBox(
                width: 500,
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      studentAttendanceStore.invoicesData[i].containsKey(
                        studentData.id,
                      )
                      ? [
                          const SizedBox(width: 10),
                          Text(
                            "\$${studentAttendanceStore.invoicesData[i][studentData.id]!.amtPayable.toStringAsFixed(2)}",
                            style: body2,
                          ),
                          const Spacer(),
                          AxisButton.text(
                            width: 100,
                            icon: Icons.edit,
                            label: 'Edit',
                            onPressed: () async {
                              final studentInvData = studentAttendanceStore
                                  .invoicesData[i][studentData.id]!;

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
                                color: (switch (studentAttendanceStore
                                    .invoicesData[i][studentData.id]!
                                    .invoiceStatus) {
                                  InvoiceStatus.ready => Colors.amber,
                                  InvoiceStatus.paid => Colors.green,
                                  InvoiceStatus.missed => Colors.red,
                                  InvoiceStatus.sent => Colors.blue,
                                }).withValues(alpha: 0.4),
                              ),
                              child: Center(
                                child: Text(
                                  studentAttendanceStore
                                      .invoicesData[i][studentData.id]!
                                      .invoiceStatus
                                      .name,
                                  style: body2.copyWith(
                                    color: AxisColors.blackPurple50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AxisButton.text(
                            width: 140,
                            icon: Icons.send,
                            label: 'Send',
                            onPressed: () async {
                              final ExportDelegate exportDelegate =
                                  ExportDelegate();
                              shownFrame = pdf.ExportFrame(
                                frameId: studentAttendanceStore
                                    .invoicesData[i][studentData.id]!
                                    .invoiceId,
                                exportDelegate: exportDelegate,
                                child: InvoiceWidget(
                                  showFonts: false,
                                  studentInvoiceData: studentAttendanceStore
                                      .invoicesData[i][studentData.id]!,
                                  teacherInvoiceData: null,
                                  total: studentAttendanceStore
                                      .invoicesData[i][studentData.id]!
                                      .amtPayable,
                                ),
                              );

                              setState(() {});

                              await WidgetsBinding.instance.endOfFrame;

                              // export the frame to a PDF Document
                              final pdfDoc = await exportDelegate
                                  .exportToPdfDocument(
                                    studentAttendanceStore
                                        .invoicesData[i][studentData.id]!
                                        .invoiceId,
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
                              await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(
                                    studentAttendanceStore
                                        .invoicesData[i][studentData.id]!
                                        .invoiceId,
                                  )
                                  .update({
                                    'invoiceStatus': InvoiceStatus.sent.name,
                                  });
                              shownFrame = null;
                              setState(() {});
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
                        ]
                      : [
                          Text(
                            'No Invoice',
                            style: body2,
                          ),
                        ],
                ),
              ),
            ),
            onTap:
                studentAttendanceStore.invoicesData[i].containsKey(
                  studentData.id,
                )
                ? () async {
                    final studentInvData =
                        studentAttendanceStore.invoicesData[i][studentData.id]!;

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
                  }
                : null,
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
                                      "\$${TeacherPayout.calculateFinalPayout(sessionsMap[teacherData.id]![monthId]!.values.fold(0, (a, b) => a + b)).toStringAsFixed(2)}",
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
              final teacherInvData = TeacherInvoiceData.fromJson(
                (await firestore
                        .collection('global')
                        .doc('archives')
                        .collection('invoices')
                        .doc(
                          TeacherData.fromJson(
                            teacherData!.data()!,
                          ).invoiceIds[monthId],
                        )
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
                        studentInvoiceData: null,
                        teacherInvoiceData: teacherInvData,
                        total: teacherInvData.amtDue,
                      ),
                    ),
                  ),
                );
              }
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
      for (final monthEntry in newSessions[teacherEntry.key]!.entries) {
        final docRef = firestore
            .collection('global')
            .doc('archives')
            .collection('invoices')
            .doc();
        final int totNumSess = newSessions[teacherEntry.key]!.values.fold(
          0,
          (a, b) => a + b.values.fold(0, (c, d) => c + d),
        );
        final double rate = TeacherPayout.calculateRate(totNumSess);
        final double payout = rate * totNumSess;
        await docRef.set(
          TeacherInvoiceData(
            invoiceDateFormatted: DateTime.now().toTimestampStringShort(),
            address: '',
            amtDue: payout,
            paidDateFormatted: '',
            invoiceStatus: InvoiceStatus.ready,
            entries: [
              for (final e in monthEntry.value.entries)
                (amt: e.value * rate, rate: rate, qty: e.value, desc: e.key),
            ],
            invoiceId: docRef.id,
            adminName: 'Jevan',
            teacherName: teacherData.name,
            terms: 'Custom',
          ).toJson(),
        );
        await firestore.collection('users').doc(teacherEntry.key).update({
          'invoiceIds.${monthEntry.key}': docRef.id,
        });
      }
    }
    sessionsMap
      ..clear()
      ..addAll(newSessions);
  }
}
