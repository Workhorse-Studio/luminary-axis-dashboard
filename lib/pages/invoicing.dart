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
          (DateTime.now().year > year)
              ? AxisButton(
                  width: 60,
                  height: 60,
                  onPressed: () => setState(() {
                    year += 1;
                  }),
                  child: Icon(
                    Icons.chevron_right,
                    size: 40,
                  ),
                )
              : const SizedBox(
                  width: 60,
                  height: 60,
                ),
        ],
        const SizedBox(width: 40),
        AxisButton.text(
          icon: Icons.refresh,
          label: 'Refresh Invoices',
          onPressed: () async {
            int numUpdated = 0;

            if (currentTabIndex == 0) {
              await studentCache.initAll(
                query: firestore
                    .collection('users')
                    .where('role', isEqualTo: 'student'),
                force: true,
              );
              await classesCache.initAll(
                collection: firestore.collection('classes'),
                force: true,
              );
              studentAttendanceStore.markStale();

              numUpdated = await studentAttendanceStore.run(
                globalState: globalState!,
                classesCache: classesCache,
                studentCache: studentCache,
              );
              setState(() {});
            } else {
              numUpdated = await fetchUpdatedTeacherInvoices(forceAll: true);
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
                dividerColor: AxisColors.blackPurple20.withValues(alpha: 0.35),
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
        dataRowHeight: 110,
        dividerThickness: 0.2,
        border: TableBorder(
          verticalInside: BorderSide(
            color: AxisColors.blackPurple20.withValues(alpha: 0.35),
            width: 1,
          ),
          horizontalInside: BorderSide(
            color: AxisColors.blackPurple20.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
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
                    minWidth: 780,
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
                    minWidth: 560,
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
        if (year <= DateTime.now().year && i <= DateTime.now().month) {
          res.add("$i-$year");
        }
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                width: 770,
                height: 100,
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
                            height: 60,
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
                                
                                final updatedDoc = await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(studentInvData.invoiceId)
                                  .get();
                                studentAttendanceStore.invoicesData[i][studentData.id] = StudentInvoiceData.fromJson(updatedDoc.data()!);
                                setState((){});
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          AxisDropdownButton<InvoiceStatus>(
                            width: 270,
                            seaprateInitialSelectionEntry: false,
                            entries: [
                              for (final status in InvoiceStatus.values)
                                (status.label, status),
                            ],
                            initalLabel: studentAttendanceStore
                                .invoicesData[i][studentData.id]!
                                .invoiceStatus
                                .label,
                            initialSelection: studentAttendanceStore
                                .invoicesData[i][studentData.id]!
                                .invoiceStatus,
                            onSelected: (invoiceStatus) async {
                              if (invoiceStatus != null) {
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
                                      'invoiceStatus': invoiceStatus.name,
                                    });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Status updated!')),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          AxisButton.text(
                            width: 140,
                            height: 60,
                            icon: Icons.send,
                            label: 'Send',
                            onPressed: () async {
                              try {
                                if (await sendInvoiceEmail(
                                  StudentData.fromJson(
                                    studentData.data()!,
                                  ).email,
                                  InvoiceWidget(
                                    showFonts: false,
                                    studentInvoiceData: studentAttendanceStore
                                        .invoicesData[i][studentData.id]!,
                                    teacherInvoiceData: null,
                                    total: studentAttendanceStore
                                        .invoicesData[i][studentData.id]!
                                        .amtPayable,
                                  ),
                                  context,
                                )) {
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
                                        'invoiceStatus':
                                            InvoiceStatus.pendingPayment.name,
                                      });
                                  studentAttendanceStore
                                      .invoicesData[i][studentData
                                      .id] = StudentInvoiceData.fromJson(
                                    (await firestore
                                            .collection('global')
                                            .doc('archives')
                                            .collection('invoices')
                                            .doc(
                                              studentAttendanceStore
                                                  .invoicesData[i][studentData
                                                      .id]!
                                                  .invoiceId,
                                            )
                                            .get())
                                        .data()!,
                                  );
                                  setState(() {});
                                }
                              } catch (e, st) {
                                print('Error in Student Send Button: $e\n$st');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Send Error: $e')),
                                  );
                                }
                              }
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      width: 510,
                      height: 100,
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
                          const SizedBox(width: 20),
                          FutureBuilderTemplate(
                            future: () async {
                              final doc = (await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(
                                    TeacherData.fromJson(
                                      teacherData.data()!,
                                    ).invoiceIds[monthId],
                                  )
                                  .get());
                              return (
                                doc,
                                TeacherInvoiceData.fromJson(doc.data()!),
                              );
                            }(),
                            builder: (context, snapshot) =>
                                AxisDropdownButton<InvoiceStatus>(
                                  width: 270,
                                  entries: [
                                    for (final status in InvoiceStatus.values)
                                      (status.label, status),
                                  ],
                                  seaprateInitialSelectionEntry: false,
                                  initalLabel:
                                      snapshot.data!.$2.invoiceStatus.label,
                                  initialSelection:
                                      snapshot.data!.$2.invoiceStatus,
                                  onSelected: (invoiceStatus) async {
                                    if (invoiceStatus != null) {
                                      await snapshot.data!.$1.reference.update({
                                        'invoiceStatus': invoiceStatus.name,
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Status updated!'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                          ),
                          const SizedBox(width: 16),
                          const Spacer(),
                          AxisButton.text(
                            width: 140,
                            height: 60,
                            icon: Icons.send,
                            label: 'Send',
                            onPressed: () async {
                              final invData = TeacherInvoiceData.fromJson(
                                (await firestore
                                        .collection('global')
                                        .doc('archives')
                                        .collection('invoices')
                                        .doc(
                                          TeacherData.fromJson(
                                            teacherData.data()!,
                                          ).invoiceIds[monthId],
                                        )
                                        .get())
                                    .data()!,
                              );
                              await sendInvoiceEmail(
                                TeacherData.fromJson(teacherData.data()!).email,
                                InvoiceWidget(
                                  showFonts: false,
                                  studentInvoiceData: null,
                                  teacherInvoiceData: invData,
                                  total: invData.amtDue,
                                ),
                                context,
                              );
                            },
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
                setState((){});
              }
            },
          ),
        );
      }
    }

    return res;
  }

  void awaitMultipleFramesRendering(Function callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await callback();
        });
      });
    });
  }

  Future<bool> sendInvoiceEmail(
    String recipientAddress,
    InvoiceWidget widget,
    BuildContext context,
  ) async {
    try {
      await precacheImage(AssetImage('assets/images/axis_logo.png'), context);
      final bytes = await m.PDFMaker().createPDF(
        IWBlankPage(child: widget),
        setup: m.PageSetup(
          context: context,
          quality: 2.0,
          scale: 1.5,
          pageFormat: m.PageFormat.a4,
          margins: 10,
        ),
      );

      final file = web.File(
        [
          bytes.toJS as JSAny,
        ].toJS,
        'invoice.pdf',
      );

      final overrideResp = await makeRequest(
        body: '{"op": "sendInvoice", "recipient": "$recipientAddress"}'.toJS,
      );

      final String msg;
      if (!overrideResp.ok) {
        msg = 'Pre-flight request to LAD server failed.';
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
        return false;
      } else {
        final response = await web.window
            .fetch(
              'https://axis-server-850501828016.asia-southeast1.run.app/api/'
                  .toJS,
              web.RequestInit(
                method: 'POST',
                body: file,
              ),
            )
            .toDart;

        if (response.ok) {
          msg = 'Invoice sent successfully!';
        } else {
          msg = 'LAD server encountered an issue while sending the invoice.';
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
        return response.ok;
      }
    } catch (e, st) {
      print('Error sending invoice email: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate/send invoice: $e')),
        );
      }
      return false;
    }
  }

  Future<int> fetchUpdatedTeacherInvoices({bool forceAll = false}) async {
    bool invoicePayloadMatches(
      TeacherInvoiceData a,
      TeacherInvoiceData b,
    ) {
      if (a.amtDue != b.amtDue) return false;
      if (a.entries.length != b.entries.length) return false;
      for (int i = 0; i < a.entries.length; i++) {
        final x = a.entries[i], y = b.entries[i];
        if (x.desc != y.desc ||
            x.qty != y.qty ||
            x.rate != y.rate ||
            x.amt != y.amt) {
          return false;
        }
      }
      return a.teacherName == b.teacherName &&
          a.adminName == b.adminName &&
          a.terms == b.terms;
    }

    int numUpdated = 0;
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
        final int totNumSess = monthEntry.value.values.fold(
          0,
          (a, b) => a + b,
        );
        final double rate = TeacherPayout.calculateRate(totNumSess);
        final double payout = rate * totNumSess;

        /// Save or Update

        DocumentSnapshot<JSON>? existingInvoice;
        DocumentReference<JSON> docRef;
        final candidate = TeacherInvoiceData(
          invoiceDateFormatted: DateTime.now().toTimestampStringShort(),
          address: '',
          amtDue: payout,
          paidDateFormatted: '',
          invoiceStatus: InvoiceStatus.pendingBilling,
          entries: [
            for (final e in monthEntry.value.entries)
              (
                amt: e.value * rate,
                rate: rate,
                qty: e.value,
                desc: ClassData.fromJson(
                  (await classesCache.get(e.key)).data()!,
                ).name,
              ),
          ],
          invoiceId: '',
          adminName: 'Jevan',
          teacherName: teacherData.name,
          terms: 'Custom',
        );

        if (teacherData.invoiceIds.containsKey(monthEntry.key)) {
          docRef = firestore
              .collection('global')
              .doc('archives')
              .collection('invoices')
              .doc(teacherData.invoiceIds[monthEntry.key]);
          existingInvoice = await docRef.get();
          final existing = TeacherInvoiceData.fromJson(existingInvoice.data()!);
          if (!forceAll && invoicePayloadMatches(existing, candidate)) {
            continue;
          }
        }

        numUpdated++;
        docRef = firestore
            .collection('global')
            .doc('archives')
            .collection('invoices')
            .doc();
        await docRef.set(candidate.toJson()..['invoiceId'] = docRef.id);

        await teacherEntry.value.reference.update({
          'invoiceIds.${monthEntry.key}': docRef.id,
        });

        teachersCache.registry[teacherEntry.key] = await teacherEntry
            .value
            .reference
            .get();
      }
    }
    sessionsMap
      ..clear()
      ..addAll(newSessions);

    return numUpdated;
  }
}

class IWBlankPage extends m.BlankPage {
  final InvoiceWidget child;
  const IWBlankPage({
    required this.child,
    super.key,
  });

  @override
  Widget createPageContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}
