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
  final Map<String, TextEditingController> studentRemarksControllers = {};
  final Map<String, Timer> studentRemarksSaveTimers = {};

  int year = DateTime.now().year;
  String selectedTeacherMonthId =
      "${DateTime.now().month}-${DateTime.now().year}";

  @override
  void dispose() {
    for (final controller in studentRemarksControllers.values) {
      controller.dispose();
    }
    for (final timer in studentRemarksSaveTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

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
              syncSelectedTeacherMonthIdForYear();
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
                    syncSelectedTeacherMonthIdForYear();
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
          const SizedBox(width: 16),
          AxisDropdownButton<String>(
            key: ValueKey('teacher-month-$year-$selectedTeacherMonthId'),
            width: 200,
            seaprateInitialSelectionEntry: false,
            entries: [
              for (final monthId in generateMonthIds())
                (formatMonthIdLabel(monthId), monthId),
            ],
            initialSelection: selectedTeacherMonthIdForYear(),
            onSelected: (monthId) {
              if (monthId != null) {
                setState(() {
                  selectedTeacherMonthId = monthId;
                });
              }
            },
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
        const SizedBox(width: 16),
        AxisButton.text(
          icon: Icons.send,
          label: 'Send All',
          onPressed: () async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Center(child: CircularProgressIndicator());
              },
            );

            int successCount = 0;
            if (currentTabIndex == 0) {
              final int currentTermIndex = globalState!.currentTermNum;
              if (studentAttendanceStore.invoicesData.length >
                  currentTermIndex) {
                for (final entry
                    in studentAttendanceStore
                        .invoicesData[currentTermIndex]
                        .entries) {
                  final studentId = entry.key;
                  final studentInvData = entry.value;
                  final studentDoc = await studentCache.get(studentId);
                  final studentData = StudentData.fromJson(studentDoc.data()!);

                  try {
                    if (await sendInvoiceEmail(
                      studentData.email,
                      StudentInvoiceWidget(
                        showFonts: false,
                        studentInvoiceData: studentInvData,
                        total: studentInvData.amtPayable,
                      ),
                      context,
                      timestampLabel: studentInvData.terms,
                    )) {
                      await firestore
                          .collection('global')
                          .doc('archives')
                          .collection('invoices')
                          .doc(studentInvData.invoiceId)
                          .update({
                            'invoiceStatus': InvoiceStatus.pendingPayment.name,
                          });
                      successCount++;
                    }
                  } catch (e, st) {
                    print(
                      'Error sending invoice for ${studentData.name}: $e\n$st',
                    );
                  }
                }
              }
            } else {
              // Teachers tab
              final monthId = selectedTeacherMonthIdForYear();
              for (final teacherEntry in teachersCache.registry.entries) {
                final teacherData = TeacherData.fromJson(
                  teacherEntry.value.data()!,
                );
                final invoiceId = teacherData.invoiceIds[monthId];
                if (invoiceId == null) continue;

                try {
                  final invDoc = await firestore
                      .collection('global')
                      .doc('archives')
                      .collection('invoices')
                      .doc(invoiceId)
                      .get();
                  if (!invDoc.exists) continue;

                  final invData = TeacherInvoiceData.fromJson(
                    invDoc.data()!,
                  ).withAgencyDetailsFromTeacher(teacherData);

                  if (await sendInvoiceEmail(
                    teacherData.email,
                    TeacherInvoiceWidget(
                      showFonts: false,
                      teacherInvoiceData: invData,
                      total: invData.amtDue,
                    ),
                    context,
                    timestampLabel: formatTeacherInvoiceEmailTimestamp(monthId),
                  )) {
                    await invDoc.reference.update({
                      'invoiceStatus': InvoiceStatus.pendingPayment.name,
                    });
                    successCount++;
                  }
                } catch (e, st) {
                  print(
                    'Error sending invoice for ${teacherData.name}: $e\n$st',
                  );
                }
              }
            }

            Navigator.of(context).pop(); // Close the loading dialog
            setState(() {});
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                SnackBar(
                  content: Text(
                    '$successCount invoices were sent successfully.',
                  ),
                ),
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
              if (!isStudentCompletelyWithdrawn(
                    student.key,
                    StudentData.fromJson(student.value.data()!),
                    classesCache,
                  ) ||
                  (studentAttendanceStore.invoicesData.length >
                          globalState!.currentTermNum &&
                      studentAttendanceStore
                          .invoicesData[globalState!.currentTermNum]
                          .containsKey(student.key)))
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
        if (year < DateTime.now().year ||
            (year == DateTime.now().year && i <= DateTime.now().month)) {
          res.add("$i-$year");
        }
      }
    }

    generateForYear(year);

    return res;
  }

  String selectedTeacherMonthIdForYear() {
    final monthIds = generateMonthIds();
    final currentMonthId = "${DateTime.now().month}-${DateTime.now().year}";
    if (monthIds.isEmpty) return currentMonthId;
    if (monthIds.contains(selectedTeacherMonthId))
      return selectedTeacherMonthId;
    if (monthIds.contains(currentMonthId)) return currentMonthId;
    return monthIds.last;
  }

  void syncSelectedTeacherMonthIdForYear() {
    selectedTeacherMonthId = selectedTeacherMonthIdForYear();
  }

  String formatMonthIdLabel(String monthId) {
    final parts = monthId.split('-');
    final month = int.tryParse(parts[0]) ?? 1;
    final y = int.tryParse(parts[1]) ?? year;
    return DateFormat('MMMM y').format(DateTime(y, month));
  }

  String formatTeacherInvoiceEmailTimestamp(String monthId) {
    final parts = monthId.split('-');
    final month = (int.tryParse(parts[0]) ?? 1).toString().padLeft(2, '0');
    final y = ((int.tryParse(parts[1]) ?? year) % 100).toString().padLeft(
      2,
      '0',
    );
    return '$month/$y';
  }

  String studentRemarksFieldKey({
    required int termIndex,
    required String studentId,
  }) => '$studentId::$termIndex';

  TextEditingController getStudentRemarksController({
    required String fieldKey,
    String initialText = '',
    bool syncExistingText = false,
  }) {
    final existing = studentRemarksControllers[fieldKey];
    if (existing != null) {
      if (syncExistingText && existing.text != initialText) {
        existing.text = initialText;
      }
      return existing;
    }

    final controller = TextEditingController(text: initialText);
    studentRemarksControllers[fieldKey] = controller;
    return controller;
  }

  Widget buildStudentRemarksField({
    required int termIndex,
    required String studentId,
    StudentInvoiceData? studentInvData,
  }) {
    final fieldKey = studentRemarksFieldKey(
      termIndex: termIndex,
      studentId: studentId,
    );
    final hasInvoice = studentInvData != null;

    return SizedBox(
      width: 180,
      child: TextField(
        key: ValueKey('remarks-$fieldKey'),
        controller: getStudentRemarksController(
          fieldKey: fieldKey,
          initialText: studentInvData?.remarks ?? '',
          syncExistingText: hasInvoice,
        ),
        style: body2,
        readOnly: !hasInvoice,
        decoration: InputDecoration(
          hint: Text(
            hasInvoice ? 'Remarks' : 'No invoice yet',
            style: body2.copyWith(
              color: AxisColors.blackPurple20.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: hasInvoice
                  ? AxisColors.lilacPurple20
                  : AxisColors.blackPurple20.withValues(alpha: 0.35),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: hasInvoice
                  ? AxisColors.lilacPurple50.withValues(alpha: 0.7)
                  : AxisColors.blackPurple20.withValues(alpha: 0.35),
            ),
          ),
        ),
        onChanged: hasInvoice
            ? (text) {
                scheduleSaveStudentRemarks(
                  termIndex: termIndex,
                  studentId: studentId,
                  fieldKey: fieldKey,
                  remarks: text,
                );
              }
            : null,
      ),
    );
  }

  Future<void> saveStudentRemarks({
    required int termIndex,
    required String studentId,
    required String remarks,
  }) async {
    final current = studentAttendanceStore.invoicesData[termIndex][studentId];
    if (current == null || current.remarks == remarks) return;

    await firestore
        .collection('global')
        .doc('archives')
        .collection('invoices')
        .doc(current.invoiceId)
        .update({
          'remarks': remarks,
        });

    studentAttendanceStore.invoicesData[termIndex][studentId] =
        StudentInvoiceData(
          invoiceDateFormatted: current.invoiceDateFormatted,
          address: current.address,
          amtPayable: current.amtPayable,
          remarks: remarks,
          dueDateFormatted: current.dueDateFormatted,
          entries: current.entries,
          invoiceId: current.invoiceId,
          parentName: current.parentName,
          studentName: current.studentName,
          invoiceStatus: current.invoiceStatus,
          terms: current.terms,
        );
  }

  void scheduleSaveStudentRemarks({
    required int termIndex,
    required String studentId,
    required String fieldKey,
    required String remarks,
  }) {
    studentRemarksSaveTimers[fieldKey]?.cancel();
    studentRemarksSaveTimers[fieldKey] = Timer(
      const Duration(milliseconds: 500),
      () async {
        try {
          await saveStudentRemarks(
            termIndex: termIndex,
            studentId: studentId,
            remarks: remarks,
          );
        } catch (e, st) {
          print('Error saving student invoice remarks: $e\n$st');
        }
      },
    );
  }

  List<DataCell> generateCellsForInvoices({
    DocumentSnapshot<JSON>? studentData,
    DocumentSnapshot<JSON>? teacherData,
  }) {
    final List<DataCell> res = [];
    if (studentData != null) {
      for (int i = 0; i < globalState!.terms.length; i++) {
        final studentInvData =
            studentAttendanceStore.invoicesData[i][studentData.id];
        res.add(
          DataCell(
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                width: 770,
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: studentInvData != null
                      ? [
                          const SizedBox(width: 10),
                          Text(
                            "\$${studentInvData.amtPayable.toStringAsFixed(2)}",
                            style: body2,
                          ),
                          const SizedBox(width: 10),
                          buildStudentRemarksField(
                            termIndex: i,
                            studentId: studentData.id,
                            studentInvData: studentInvData,
                          ),
                          const Spacer(),
                          AxisButton.text(
                            width: 100,
                            height: 60,
                            icon: Icons.edit,
                            label: 'Edit',
                            onPressed: () async {
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
                                studentAttendanceStore
                                        .invoicesData[i][studentData.id] =
                                    StudentInvoiceData.fromJson(
                                      updatedDoc.data()!,
                                    );
                                setState(() {});
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
                                  StudentInvoiceWidget(
                                    showFonts: false,
                                    studentInvoiceData: studentAttendanceStore
                                        .invoicesData[i][studentData.id]!,
                                    total: studentAttendanceStore
                                        .invoicesData[i][studentData.id]!
                                        .amtPayable,
                                  ),
                                  context,
                                  timestampLabel: studentAttendanceStore
                                      .invoicesData[i][studentData.id]!
                                      .terms,
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
                          const SizedBox(width: 10),
                          buildStudentRemarksField(
                            termIndex: i,
                            studentId: studentData.id,
                          ),
                          const SizedBox(width: 16),
                          Text('No Invoice', style: body2),
                        ],
                ),
              ),
            ),
            onTap: studentInvData != null
                ? () async {
                    if (context.mounted) {
                      await showDialog(
                        context: context,
                        builder: (_) => Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.height * 0.85,
                            child: SingleChildScrollView(
                              child: StudentInvoiceWidget(
                                studentInvoiceData: studentInvData,
                                total: studentInvData.amtPayable,
                              ),
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
                              final invoiceId = TeacherData.fromJson(
                                teacherData.data()!,
                              ).invoiceIds[monthId];
                              if (invoiceId == null) return null;
                              final doc = await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(invoiceId)
                                  .get();
                              if (!doc.exists || doc.data() == null)
                                return null;
                              return (
                                doc,
                                TeacherInvoiceData.fromJson(doc.data()!),
                              );
                            }(),
                            builder: (context, snapshot) =>
                                snapshot.data == null
                                ? const SizedBox(width: 270)
                                : AxisDropdownButton<InvoiceStatus>(
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
                                        await snapshot.data!.$1.reference
                                            .update({
                                              'invoiceStatus':
                                                  invoiceStatus.name,
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
                              final invoiceId = TeacherData.fromJson(
                                teacherData.data()!,
                              ).invoiceIds[monthId];
                              if (invoiceId == null) return;
                              final doc = await firestore
                                  .collection('global')
                                  .doc('archives')
                                  .collection('invoices')
                                  .doc(invoiceId)
                                  .get();
                              if (!doc.exists || doc.data() == null) return;
                              final currentTeacherData = TeacherData.fromJson(
                                teacherData.data()!,
                              );
                              final invData =
                                  TeacherInvoiceData.fromJson(
                                    doc.data()!,
                                  ).withAgencyDetailsFromTeacher(
                                    currentTeacherData,
                                  );
                              await sendInvoiceEmail(
                                currentTeacherData.email,
                                TeacherInvoiceWidget(
                                  showFonts: false,
                                  teacherInvoiceData: invData,
                                  total: invData.amtDue,
                                ),
                                context,
                                timestampLabel:
                                    formatTeacherInvoiceEmailTimestamp(monthId),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(''),
            onTap: () async {
              final invoiceId = TeacherData.fromJson(
                teacherData!.data()!,
              ).invoiceIds[monthId];
              if (invoiceId == null) return;
              final doc = await firestore
                  .collection('global')
                  .doc('archives')
                  .collection('invoices')
                  .doc(invoiceId)
                  .get();
              if (!doc.exists || doc.data() == null) return;

              final teacherInvData =
                  TeacherInvoiceData.fromJson(
                    doc.data()!,
                  ).withAgencyDetailsFromTeacher(
                    TeacherData.fromJson(teacherData.data()!),
                  );

              if (context.mounted) {
                await showDialog(
                  context: context,
                  builder: (_) => Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.height * 0.85,
                      child: SingleChildScrollView(
                        child: TeacherInvoiceWidget(
                          teacherInvoiceData: teacherInvData,
                          total: teacherInvData.amtDue,
                        ),
                      ),
                    ),
                  ),
                );
                setState(() {});
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
    Widget widget,
    BuildContext context, {
    required String timestampLabel,
  }) async {
    String? clientCaseId;
    String? serverCaseId;
    try {
      await runArmTrackedAction<void>(
        feature: 'invoicing',
        operation: 'send_invoice_email',
        severity: ArmSeverity.moderate,
        category: 'external_integration',
        captureScreenshot: true,
        tags: <String, dynamic>{
          'recipient': recipientAddress,
          'widgetType': widget.runtimeType.toString(),
        },
        recoverySnapshotBuilder: () => <String, dynamic>{
          'recipient': recipientAddress,
          'timestampLabel': timestampLabel,
          'widgetType': widget.runtimeType.toString(),
        },
        onReported: (result) {
          clientCaseId = result.caseId;
        },
        action: () async {
          await precacheImage(
            AssetImage('assets/images/axis_logo.png'),
            context,
          );

          late final List<InvoiceEntry> allEntries;
          late final Widget firstPageWidget;
          late final Widget Function({
            required List<InvoiceEntry> entries,
            required bool isFirstPage,
            required bool isLastPage,
            required int startIndex,
          })
          pagedWidgetBuilder;

          if (widget is StudentInvoiceWidget) {
            allEntries =
                widget.overrideEntries ?? widget.studentInvoiceData.entries;
            firstPageWidget = widget;
            pagedWidgetBuilder =
                ({
                  required List<InvoiceEntry> entries,
                  required bool isFirstPage,
                  required bool isLastPage,
                  required int startIndex,
                }) => StudentInvoiceWidget(
                  studentInvoiceData: widget.studentInvoiceData,
                  overrideEntries: entries,
                  showFonts: widget.showFonts,
                  showTopHeader: isFirstPage,
                  showBottomFooter: isLastPage,
                  startIndex: startIndex,
                  total: widget.total,
                  maskEditableFields: widget.maskEditableFields,
                );
          } else if (widget is TeacherInvoiceWidget) {
            allEntries =
                widget.overrideEntries ?? widget.teacherInvoiceData.entries;
            firstPageWidget = widget;
            pagedWidgetBuilder =
                ({
                  required List<InvoiceEntry> entries,
                  required bool isFirstPage,
                  required bool isLastPage,
                  required int startIndex,
                }) => TeacherInvoiceWidget(
                  teacherInvoiceData: widget.teacherInvoiceData,
                  overrideEntries: entries,
                  showFonts: widget.showFonts,
                  showTopHeader: isFirstPage,
                  showBottomFooter: isLastPage,
                  startIndex: startIndex,
                  total: widget.total,
                  maskEditableFields: widget.maskEditableFields,
                );
          } else {
            throw ArgumentError(
              'Unsupported invoice widget type: ${widget.runtimeType}',
            );
          }

          final List<IWBlankPage> pages = [];
          if (allEntries.length <= 2) {
            pages.add(IWBlankPage(child: firstPageWidget));
          } else {
            int i = 0;
            while (i < allEntries.length) {
              final bool isFirstPage = i == 0;
              final int chunkSize = isFirstPage ? 2 : 12;
              final int end = (i + chunkSize < allEntries.length)
                  ? i + chunkSize
                  : allEntries.length;

              final chunk = allEntries.sublist(i, end);
              final bool isLastPage = end == allEntries.length;

              pages.add(
                IWBlankPage(
                  child: pagedWidgetBuilder(
                    entries: chunk,
                    isFirstPage: isFirstPage,
                    isLastPage: isLastPage,
                    startIndex: i,
                  ),
                ),
              );

              i = end;
            }
          }

          final bytes = await m.PDFMaker().createMultiPagePDF(
            pages,
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
            body: jsonEncode({
              'op': 'sendInvoice',
              'recipient': recipientAddress,
              'timestamp': timestampLabel,
              'includeFeeStructure': widget is StudentInvoiceWidget,
            }).toJS,
          );
          serverCaseId = overrideResp.armCaseId;
          if (!overrideResp.ok) {
            throwArmResponseFailure(
              statusCode: overrideResp.statusCode,
              body: overrideResp.body,
              rawBody: overrideResp.rawBody,
              armCaseId: overrideResp.armCaseId,
            );
          }

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
          serverCaseId = response.headers.get('x-arm-case-id') ?? serverCaseId;
          if (!response.ok) {
            final rawBody = (await response.text().toDart).toDart;
            throwArmResponseFailure(
              statusCode: response.status,
              body: tryDecodeJsonObject(rawBody),
              rawBody: rawBody,
              armCaseId: serverCaseId,
            );
          }
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(content: Text('Invoice sent successfully!')),
        );
      }
      return true;
    } catch (e, st) {
      print('Error sending invoice email: $e\n$st');
      showArmSnackBar(
        context,
        'Failed to generate/send invoice.',
        caseId: serverCaseId ?? clientCaseId,
      );
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
      return a.agencyName == b.agencyName &&
          a.agencyContact == b.agencyContact &&
          a.agencyEmail == b.agencyEmail &&
          a.agencyAddress == b.agencyAddress &&
          a.dueDateFormatted == b.dueDateFormatted;
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
          final String monthId = attendanceMonthId(attEntry.key);
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
        final generatedAt = DateTime.now();

        /// Save or Update

        DocumentSnapshot<JSON>? existingInvoice;
        DocumentReference<JSON> docRef;
        final candidate = TeacherInvoiceData(
          invoiceDateFormatted: generatedAt.toTimestampStringShort(),
          amtDue: payout,
          dueDateFormatted: generatedAt
              .add(const Duration(days: 14))
              .toTimestampStringShort(),
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
          agencyName: teacherData.agencyName.isNotEmpty
              ? teacherData.agencyName
              : teacherData.name,
          agencyContact: teacherData.agencyContact,
          agencyEmail: teacherData.agencyEmail,
          agencyAddress: teacherData.agencyAddress,
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
  final Widget child;
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
