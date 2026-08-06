part of axis_dashboard;

const int invoiceRowsPerPage = 15;

bool invoiceNameMatchesSearch(String name, String query) {
  final normalizedName = name.toLowerCase().trim();
  final normalizedQuery = query.toLowerCase().trim();
  if (normalizedQuery.isEmpty) return true;

  final nameTerms = normalizedName
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty);
  final queryTerms = normalizedQuery
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty);

  return queryTerms.every(
    (queryTerm) =>
        normalizedName.contains(queryTerm) ||
        nameTerms.any(
          (nameTerm) =>
              _invoiceSearchEditDistance(nameTerm, queryTerm) <=
              (queryTerm.length < 3 ? 0 : (queryTerm.length >= 7 ? 2 : 1)),
        ),
  );
}

int _invoiceSearchEditDistance(String left, String right) {
  if (left == right) return 0;
  if (left.isEmpty) return right.length;
  if (right.isEmpty) return left.length;

  var previous = List<int>.generate(right.length + 1, (index) => index);
  for (var leftIndex = 0; leftIndex < left.length; leftIndex++) {
    final current = List<int>.filled(right.length + 1, 0);
    current[0] = leftIndex + 1;
    for (var rightIndex = 0; rightIndex < right.length; rightIndex++) {
      final substitutionCost = left[leftIndex] == right[rightIndex] ? 0 : 1;
      current[rightIndex + 1] = min(
        min(current[rightIndex] + 1, previous[rightIndex + 1] + 1),
        previous[rightIndex] + substitutionCost,
      );
    }
    previous = current;
  }
  return previous.last;
}

class _InvoicePartyRow {
  final String id;
  final String name;
  final DocumentSnapshot<JSON> document;

  const _InvoicePartyRow({
    required this.id,
    required this.name,
    required this.document,
  });
}

class _InvoiceRowsSource extends DataTableSource {
  final List<_InvoicePartyRow> rows;
  final DataRow Function(_InvoicePartyRow row, int index) rowBuilder;

  _InvoiceRowsSource({required this.rows, required this.rowBuilder});

  @override
  DataRow? getRow(int index) =>
      index < rows.length ? rowBuilder(rows[index], index) : null;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => rows.length;

  @override
  int get selectedRowCount => 0;
}

class InvoicingPage extends StatefulWidget {
  const InvoicingPage({super.key});

  @override
  State<StatefulWidget> createState() => InvoicingPageState();
}

class InvoicingPageState extends State<InvoicingPage> {
  int currentTabIndex = 0;
  final TextEditingController searchController = TextEditingController();
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
  final Map<String, String> classIdToTeacherNameMap = {};
  final Map<String, TextEditingController> studentRemarksControllers = {};
  final Map<String, Timer> studentRemarksSaveTimers = {};
  Future<Map<String, DocumentSnapshot<JSON>>>? _studentTabFuture;
  Future<Map<String, DocumentSnapshot<JSON>>>? _teacherTabFuture;
  Timer? _searchTimer;
  String _searchQuery = '';
  Future<InvoiceMailBatchSnapshot>? _activeMailBatchRun;

  int year = DateTime.now().year;
  String selectedTeacherMonthId =
      "${DateTime.now().month}-${DateTime.now().year}";

  @override
  void dispose() {
    searchController.dispose();
    _searchTimer?.cancel();
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
        IconButton(
          tooltip: 'Invoice mailing errors',
          onPressed: _showHistoricalMailIssuesDialog,
          icon: const Icon(Icons.error_outline),
        ),
        const SizedBox(width: 8),
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
        const SizedBox(width: 24),
        SizedBox(
          width: 240,
          height: 50,
          child: TextField(
            key: const ValueKey('invoice-name-search'),
            controller: searchController,
            onChanged: _scheduleSearch,
            onSubmitted: _applySearch,
            style: body2,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by name',
              hintStyle: body2.copyWith(
                color: AxisColors.blackPurple20.withValues(alpha: 0.5),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        _applySearch('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              focusedBorder: const OutlineInputBorder(
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
        if (currentTabIndex == 0) ...[
          const SizedBox(width: 16),
          AxisButton.text(
            key: const ValueKey('manual-invoice-open'),
            icon: Icons.note_add_outlined,
            label: 'Manual Invoice',
            onPressed: _showManualInvoiceDialog,
          ),
        ],
        const SizedBox(width: 16),
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
          onPressed: _activeMailBatchRun == null ? _sendAllInvoices : null,
        ),
      ],
      body: (context) => DefaultTabController(
        length: 2,
        child: SizedBox.expand(
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
              Expanded(
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
      future: _tabFuture(viewType),
      builder: (context, _) {
        final rows = _visibleRows(viewType);
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.copyWith(bodySmall: body2),
          ),
          child: PaginatedDataTable2(
            key: ValueKey('$viewType-$year-$_searchQuery'),
            source: _InvoiceRowsSource(
              rows: rows,
              rowBuilder: (row, index) => _buildInvoiceRow(viewType, row),
            ),
            autoRowsToHeight: false,
            rowsPerPage: invoiceRowsPerPage,
            renderEmptyRowsInTheEnd: false,
            showCheckboxColumn: false,
            showFirstLastButtons: true,
            wrapInCard: false,
            empty: Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'No invoice entries found.'
                    : 'No names match your search.',
                style: body2,
              ),
            ),
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
          ),
        );
      },
    );
  }

  Future<Map<String, DocumentSnapshot<JSON>>> _tabFuture(String viewType) {
    if (viewType == 'student') {
      return _studentTabFuture ??= _loadStudentTab();
    }
    return _teacherTabFuture ??= _loadTeacherTab();
  }

  Future<Map<String, DocumentSnapshot<JSON>>> _loadStudentTab() async {
    globalState ??= GlobalState.fromJson(
      (await firestore.collection('global').doc('state').get()).data()!,
    );
    await studentCache.initAll(
      query: firestore.collection('users').where('role', isEqualTo: 'student'),
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
  }

  Future<Map<String, DocumentSnapshot<JSON>>> _loadTeacherTab() async {
    await classesCache.initAll(collection: firestore.collection('classes'));
    await teachersCache.initAll(
      query: firestore.collection('users').where('role', isEqualTo: 'teacher'),
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

  List<_InvoicePartyRow> _visibleRows(String viewType) {
    if (viewType == 'teacher') {
      return [
        for (final entry in teachersCache.registry.entries)
          if (TeacherData.fromJson(entry.value.data()!) case final teacher)
            if (invoiceNameMatchesSearch(teacher.name, _searchQuery))
              _InvoicePartyRow(
                id: entry.key,
                name: teacher.name,
                document: entry.value,
              ),
      ];
    }

    return [
      for (final entry in studentCache.registry.entries)
        if (StudentData.fromJson(entry.value.data()!) case final student)
          if (invoiceNameMatchesSearch(student.name, _searchQuery) &&
              (!isStudentCompletelyWithdrawn(
                    entry.key,
                    student,
                    classesCache,
                  ) ||
                  (studentAttendanceStore.invoicesData.length >
                          globalState!.currentTermNum &&
                      studentAttendanceStore
                          .invoicesData[globalState!.currentTermNum]
                          .containsKey(entry.key))))
            _InvoicePartyRow(
              id: entry.key,
              name: student.name,
              document: entry.value,
            ),
    ];
  }

  DataRow _buildInvoiceRow(String viewType, _InvoicePartyRow row) {
    final isStudent = viewType == 'student';
    return DataRow2(
      key: ValueKey('$viewType-${row.id}'),
      cells: [
        DataCell(
          Text(row.name, style: body2),
          onTap: isStudent
              ? () => _showStudentInfo(row.id, row.document)
              : null,
        ),
        ...generateCellsForInvoices(
          studentData: isStudent ? row.document : null,
          teacherData: isStudent ? null : row.document,
        ),
      ],
    );
  }

  void _scheduleSearch(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 160),
      () => _applySearch(query),
    );
  }

  void _applySearch(String query) {
    _searchTimer?.cancel();
    final normalizedQuery = query.trim();
    if (!mounted || normalizedQuery == _searchQuery) return;
    setState(() => _searchQuery = normalizedQuery);
  }

  Future<void> _showStudentInfo(
    String studentId,
    DocumentSnapshot<JSON> studentDocument,
  ) async {
    await teachersCache.initAll(
      query: firestore.collection('users').where('role', isEqualTo: 'teacher'),
    );
    classIdToTeacherNameMap.clear();
    for (final teacherDocument in teachersCache.registry.values) {
      final teacher = TeacherData.fromJson(teacherDocument.data()!);
      for (final classId in teacher.classIds) {
        classIdToTeacherNameMap[classId] = teacher.name;
      }
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => StudentInfoDialog(
        studentId: studentId,
        studentData: studentDocument,
        classIdToTeacherNameMap: classIdToTeacherNameMap,
      ),
    );
  }

  Future<void> _showManualInvoiceDialog() async {
    await studentCache.initAll(
      query: firestore.collection('users').where('role', isEqualTo: 'student'),
    );
    if (!mounted) return;

    final students =
        studentCache.registry.values
            .map((document) => StudentData.fromJson(document.data()!))
            .toList()
          ..sort((left, right) => left.name.compareTo(right.name));

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ManualInvoiceDialog(
        students: students,
        onSend: (student, invoice) => sendInvoiceEmail(
          student.email,
          StudentInvoiceWidget(
            showFonts: false,
            studentInvoiceData: invoice,
            total: invoice.amtPayable,
          ),
          context,
          timestampLabel: 'Manual Invoice ${invoice.invoiceDateFormatted}',
          invoiceId: invoice.invoiceId,
          recipientName: student.name,
        ),
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
                            onPressed: _activeMailBatchRun == null
                                ? () => _sendStudentInvoice(
                                    studentId: studentData.id,
                                    invoice: studentAttendanceStore
                                        .invoicesData[i][studentData.id]!,
                                    termIndex: i,
                                  )
                                : null,
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
      if (teacherData == null) return res;
      final parsedTeacherData = TeacherData.fromJson(teacherData.data()!);
      final mIds = generateMonthIds();
      for (final String monthId in mIds) {
        final invoiceId = parsedTeacherData.invoiceIds[monthId];
        final teacherInvoiceDocument = invoiceId == null
            ? null
            : teachersInvoiceCache.registry[invoiceId];
        final teacherInvoiceData =
            teacherInvoiceDocument?.exists == true &&
                teacherInvoiceDocument!.data() != null
            ? TeacherInvoiceData.fromJson(teacherInvoiceDocument.data()!)
            : null;
        res.add(
          DataCell(
            sessionsMap[teacherData.id]?.containsKey(monthId) == true
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
                          teacherInvoiceData == null
                              ? const SizedBox(width: 270)
                              : AxisDropdownButton<InvoiceStatus>(
                                  width: 270,
                                  entries: [
                                    for (final status in InvoiceStatus.values)
                                      (status.label, status),
                                  ],
                                  seaprateInitialSelectionEntry: false,
                                  initalLabel:
                                      teacherInvoiceData.invoiceStatus.label,
                                  initialSelection:
                                      teacherInvoiceData.invoiceStatus,
                                  onSelected: (invoiceStatus) async {
                                    if (invoiceStatus != null) {
                                      await teacherInvoiceDocument!.reference
                                          .update({
                                            'invoiceStatus': invoiceStatus.name,
                                          });
                                      final updatedDocument =
                                          await teacherInvoiceDocument.reference
                                              .get();
                                      teachersInvoiceCache
                                              .registry[updatedDocument.id] =
                                          updatedDocument;
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
                          const SizedBox(width: 16),
                          const Spacer(),
                          AxisButton.text(
                            width: 140,
                            height: 60,
                            icon: Icons.send,
                            label: 'Send',
                            onPressed: _activeMailBatchRun == null
                                ? () => _sendTeacherInvoice(
                                    teacher: TeacherData.fromJson(
                                      teacherData.data()!,
                                    ),
                                    monthId: monthId,
                                  )
                                : null,
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
    ValueChanged<String>? onProgress,
    String invoiceId = 'Manual invoice',
    String recipientName = 'Manual recipient',
  }) async {
    if (_activeMailBatchRun != null) {
      return false;
    }
    final job = _InvoiceMailJob(
      id: '$invoiceId-${DateTime.now().microsecondsSinceEpoch}',
      invoiceId: invoiceId,
      recipientName: recipientName,
      recipientEmail: recipientAddress,
      load: () async => _InvoiceMailPayload(
        invoiceWidget: widget,
        recipientName: recipientName,
        recipientEmail: recipientAddress,
        timestampLabel: timestampLabel,
        includeFeeStructure: widget is StudentInvoiceWidget,
        markPendingPayment: () async {},
        onProgress: onProgress,
      ),
    );
    final result = await _startInvoiceMailBatch(<_InvoiceMailJob>[job]);
    return result.executions.single.delivered;
  }

  void _sendAllInvoices() {
    unawaited(_sendAllInvoicesAsync());
  }

  Future<void> _sendAllInvoicesAsync() async {
    final jobs = currentTabIndex == 0
        ? _studentInvoiceJobsForCurrentTerm()
        : _teacherInvoiceJobsForSelectedMonth();
    await _startInvoiceMailBatch(jobs);
  }

  List<_InvoiceMailJob> _studentInvoiceJobsForCurrentTerm() {
    final currentTermIndex = globalState?.currentTermNum;
    if (currentTermIndex == null ||
        studentAttendanceStore.invoicesData.length <= currentTermIndex) {
      return const <_InvoiceMailJob>[];
    }
    return <_InvoiceMailJob>[
      for (final entry
          in studentAttendanceStore.invoicesData[currentTermIndex].entries)
        _studentInvoiceJob(
          studentId: entry.key,
          invoice: entry.value,
          termIndex: currentTermIndex,
        ),
    ];
  }

  _InvoiceMailJob _studentInvoiceJob({
    required String studentId,
    required StudentInvoiceData invoice,
    required int termIndex,
  }) {
    final cachedDocument = studentCache.registry[studentId];
    final cachedStudent = cachedDocument?.data() == null
        ? null
        : StudentData.fromJson(cachedDocument!.data()!);
    return _InvoiceMailJob(
      id: '${invoice.invoiceId}-$studentId',
      invoiceId: invoice.invoiceId,
      recipientName: cachedStudent?.name ?? invoice.studentName,
      recipientEmail: cachedStudent?.email ?? 'Unknown',
      load: () async {
        final studentDocument = await studentCache.get(studentId);
        final student = StudentData.fromJson(studentDocument.data()!);
        final invoiceReference = firestore
            .collection('global')
            .doc('archives')
            .collection('invoices')
            .doc(invoice.invoiceId);
        return _InvoiceMailPayload(
          invoiceWidget: StudentInvoiceWidget(
            showFonts: false,
            studentInvoiceData: invoice,
            total: invoice.amtPayable,
          ),
          recipientName: student.name,
          recipientEmail: student.email,
          timestampLabel: invoice.terms,
          includeFeeStructure: true,
          markPendingPayment: () async {
            await markInvoicePendingPayment(invoiceReference);
            final updatedDocument = await invoiceReference.get();
            studentInvoicesCache.registry[invoice.invoiceId] = updatedDocument;
            studentAttendanceStore.invoicesData[termIndex][studentId] =
                StudentInvoiceData.fromJson(updatedDocument.data()!);
          },
        );
      },
    );
  }

  List<_InvoiceMailJob> _teacherInvoiceJobsForSelectedMonth() {
    final monthId = selectedTeacherMonthIdForYear();
    return <_InvoiceMailJob>[
      for (final document in teachersCache.registry.values)
        if (TeacherData.fromJson(document.data()!) case final teacher)
          if (teacher.invoiceIds[monthId] case final invoiceId?)
            _teacherInvoiceJob(
              teacher: teacher,
              invoiceId: invoiceId,
              monthId: monthId,
            ),
    ];
  }

  _InvoiceMailJob _teacherInvoiceJob({
    required TeacherData teacher,
    required String invoiceId,
    required String monthId,
  }) => _InvoiceMailJob(
    id: '$invoiceId-${teacher.email}',
    invoiceId: invoiceId,
    recipientName: teacher.name,
    recipientEmail: teacher.email,
    load: () async {
      final invoiceReference = firestore
          .collection('global')
          .doc('archives')
          .collection('invoices')
          .doc(invoiceId);
      final document = await invoiceReference.get();
      if (!document.exists || document.data() == null) {
        throw StateError('Invoice $invoiceId could not be loaded.');
      }
      final invoice = TeacherInvoiceData.fromJson(
        document.data()!,
      ).withAgencyDetailsFromTeacher(teacher);
      return _InvoiceMailPayload(
        invoiceWidget: TeacherInvoiceWidget(
          showFonts: false,
          teacherInvoiceData: invoice,
          total: invoice.amtDue,
        ),
        recipientName: teacher.name,
        recipientEmail: teacher.email,
        timestampLabel: formatTeacherInvoiceEmailTimestamp(monthId),
        includeFeeStructure: false,
        markPendingPayment: () async {
          await markInvoicePendingPayment(invoiceReference);
          teachersInvoiceCache.registry[invoiceId] = await invoiceReference
              .get();
        },
      );
    },
  );

  void _sendStudentInvoice({
    required String studentId,
    required StudentInvoiceData invoice,
    required int termIndex,
  }) {
    final job = _studentInvoiceJob(
      studentId: studentId,
      invoice: invoice,
      termIndex: termIndex,
    );
    unawaited(_startInvoiceMailBatch(<_InvoiceMailJob>[job]));
  }

  void _sendTeacherInvoice({
    required TeacherData teacher,
    required String monthId,
  }) {
    final invoiceId = teacher.invoiceIds[monthId];
    if (invoiceId == null) return;
    unawaited(
      _startInvoiceMailBatch(<_InvoiceMailJob>[
        _teacherInvoiceJob(
          teacher: teacher,
          invoiceId: invoiceId,
          monthId: monthId,
        ),
      ]),
    );
  }

  Future<InvoiceMailBatchSnapshot> _startInvoiceMailBatch(
    List<_InvoiceMailJob> jobs,
  ) async {
    final running = _activeMailBatchRun;
    if (running != null) {
      return running;
    }
    if (jobs.isEmpty) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('There are no invoices to send.')),
        );
      }
      return const InvoiceMailBatchSnapshot(<InvoiceMailExecutionState>[]);
    }

    final controller = InvoiceMailBatchController(<InvoiceMailExecutionState>[
      for (final job in jobs)
        InvoiceMailExecutionState(
          id: job.id,
          invoiceId: job.invoiceId,
          recipientName: job.recipientName,
          recipientEmail: job.recipientEmail,
        ),
    ]);
    _showInvoiceMailProgressSnackBar(controller);
    final run = () async {
      await runBoundedInvoiceMailTasks<_InvoiceMailJob>(
        jobs,
        maximumConcurrent: 2,
        action: (job) => _runInvoiceMailJob(job, controller),
      );
      if (mounted) setState(() {});
      return controller.value;
    }();
    _activeMailBatchRun = run;
    if (mounted) setState(() {});
    try {
      return await run;
    } finally {
      if (identical(_activeMailBatchRun, run)) {
        _activeMailBatchRun = null;
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _runInvoiceMailJob(
    _InvoiceMailJob job,
    InvoiceMailBatchController controller,
  ) async {
    String? clientCaseId;
    var currentStage = InvoiceMailStage.loading;
    var recipientName = job.recipientName;
    var recipientEmail = job.recipientEmail;
    try {
      await runArmTrackedAction<void>(
        feature: 'invoicing',
        operation: 'send_invoice_email',
        severity: ArmSeverity.moderate,
        category: 'external_integration',
        captureScreenshot: false,
        tags: <String, dynamic>{
          'invoiceId': job.invoiceId,
          'recipient': job.recipientEmail,
        },
        recoverySnapshotBuilder: () => <String, dynamic>{
          'invoiceId': job.invoiceId,
          'recipient': recipientEmail,
          'stage': currentStage.name,
        },
        onReported: (result) => clientCaseId = result.caseId,
        action: () async {
          controller.updateStage(job.id, currentStage);
          final payload = await job.load();
          recipientName = payload.recipientName;
          recipientEmail = payload.recipientEmail;
          controller.updateRecipient(
            job.id,
            name: recipientName,
            email: recipientEmail,
          );
          payload.onProgress?.call('started');
          await Future<void>.delayed(Duration.zero);
          currentStage = InvoiceMailStage.preparing;
          controller.updateStage(job.id, currentStage);
          final pdfBytes = await _createInvoicePdf(
            payload.invoiceWidget,
            onProgress: payload.onProgress,
          );
          await Future<void>.delayed(Duration.zero);
          currentStage = InvoiceMailStage.transferring;
          controller.updateStage(job.id, currentStage);
          final outcome = await _uploadInvoicePdf(
            job: job,
            payload: payload,
            bytes: pdfBytes,
          );
          for (final serverIssue in outcome.serverIssues) {
            final issue = InvoiceMailIssue(
              invoiceId: job.invoiceId,
              recipientName: recipientName,
              recipientEmail: recipientEmail,
              side: InvoiceMailIssueSide.server,
              stage: serverIssue.stage,
              message: serverIssue.message,
              occurredAt: DateTime.now(),
              armCaseId: serverIssue.armCaseId,
            );
            controller.addIssue(job.id, issue);
            await _recordInvoiceMailIssue(issue);
          }
          if (!outcome.delivered) {
            throw const _InvoiceMailFailure(
              side: InvoiceMailIssueSide.server,
              stage: 'smtp_delivery',
              message: 'The server did not confirm SMTP delivery.',
            );
          }
          currentStage = InvoiceMailStage.updatingPaymentStatus;
          controller.updateStage(job.id, currentStage);
          try {
            await payload.markPendingPayment();
          } catch (error, stackTrace) {
            String? statusCaseId;
            try {
              await runArmTrackedAction<void>(
                feature: 'invoicing',
                operation: 'mark_invoice_pending_payment',
                severity: ArmSeverity.moderate,
                category: 'data_write',
                captureScreenshot: false,
                onReported: (result) => statusCaseId = result.caseId,
                action: () => Error.throwWithStackTrace(error, stackTrace),
              );
            } catch (_) {}
            final issue = InvoiceMailIssue(
              invoiceId: job.invoiceId,
              recipientName: recipientName,
              recipientEmail: recipientEmail,
              side: InvoiceMailIssueSide.client,
              stage: 'payment_status_update',
              message:
                  'Email was sent, but payment status could not be changed to Pending Payment: $error',
              occurredAt: DateTime.now(),
              armCaseId: statusCaseId,
            );
            controller.addIssue(job.id, issue);
            await _recordInvoiceMailIssue(issue);
          }
          controller.complete(job.id, delivered: true);
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Invoice mail ${job.invoiceId} failed: $error\n$stackTrace');
      final failure = error is _InvoiceMailFailure ? error : null;
      final issue = InvoiceMailIssue(
        invoiceId: job.invoiceId,
        recipientName: recipientName,
        recipientEmail: recipientEmail,
        side: failure?.side ?? InvoiceMailIssueSide.client,
        stage: failure?.stage ?? currentStage.name,
        message: failure?.message ?? _readableClientMailError(error),
        occurredAt: DateTime.now(),
        armCaseId: failure?.armCaseId ?? clientCaseId,
      );
      controller.addIssue(job.id, issue);
      await _recordInvoiceMailIssue(issue);
      controller.complete(job.id, delivered: false);
    }
  }

  Future<Uint8List> _createInvoicePdf(
    Widget widget, {
    ValueChanged<String>? onProgress,
  }) async {
    await precacheImage(
      const AssetImage('assets/images/axis_logo.png'),
      context,
    );
    onProgress?.call('asset_precached');
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
      allEntries = widget.overrideEntries ?? widget.studentInvoiceData.entries;
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
      allEntries = widget.overrideEntries ?? widget.teacherInvoiceData.entries;
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

    final pages = <IWBlankPage>[];
    if (allEntries.length <= 2) {
      pages.add(IWBlankPage(child: firstPageWidget));
    } else {
      var entryIndex = 0;
      while (entryIndex < allEntries.length) {
        final isFirstPage = entryIndex == 0;
        final chunkSize = isFirstPage ? 2 : 12;
        final end = min(entryIndex + chunkSize, allEntries.length);
        pages.add(
          IWBlankPage(
            child: pagedWidgetBuilder(
              entries: allEntries.sublist(entryIndex, end),
              isFirstPage: isFirstPage,
              isLastPage: end == allEntries.length,
              startIndex: entryIndex,
            ),
          ),
        );
        entryIndex = end;
      }
    }
    onProgress?.call('pages_prepared');
    if (!mounted) {
      throw StateError('The invoicing page was closed during PDF preparation.');
    }
    final bytes = await m.PDFMaker().createMultiPagePDF(
      pages,
      setup: m.PageSetup(
        context: context,
        quality: 2,
        scale: 1.5,
        pageFormat: m.PageFormat.a4,
        margins: 10,
      ),
    );
    onProgress?.call('pdf_generated');
    return bytes;
  }

  Future<_InvoiceDeliveryOutcome> _uploadInvoicePdf({
    required _InvoiceMailJob job,
    required _InvoiceMailPayload payload,
    required Uint8List bytes,
  }) async {
    final file = web.File(<JSAny>[bytes.toJS].toJS, 'invoice.pdf');
    final encodedMetadata = base64UrlEncode(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'invoiceId': job.invoiceId,
          'recipientName': payload.recipientName,
          'recipient': payload.recipientEmail,
          'timestamp': payload.timestampLabel,
          'includeFeeStructure': payload.includeFeeStructure,
        }),
      ),
    );
    final idToken = await auth.currentUser?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const _InvoiceMailFailure(
        side: InvoiceMailIssueSide.client,
        stage: 'authentication',
        message: 'Please sign in again before sending invoices.',
      );
    }
    payload.onProgress?.call('pdf_upload_started');
    final response = await makeRequest(
      url:
          'https://axis-server-850501828016.asia-southeast1.run.app/api/invoices/send',
      body: file,
      headers: <String, String>{
        'Content-Type': 'application/pdf',
        'X-Invoice-Metadata': encodedMetadata,
        'Authorization': 'Bearer $idToken',
      },
    );
    final body = response.body;
    if (!response.ok || body == null) {
      final error = body?['error'];
      final errorMessage = error is Map
          ? error['message']?.toString()
          : error?.toString();
      throw _InvoiceMailFailure(
        side: InvoiceMailIssueSide.server,
        stage: (body?['failedStage'] as String?) ?? 'server_processing',
        message: errorMessage?.trim().isNotEmpty == true
            ? errorMessage!.trim()
            : 'Server rejected invoice delivery (HTTP ${response.statusCode}).',
        armCaseId: response.armCaseId,
      );
    }
    payload.onProgress?.call('server_completed');
    final issues = <({String stage, String message, String? armCaseId})>[];
    if (body['issues'] case final List<Object?> rawIssues) {
      for (final rawIssue in rawIssues) {
        if (rawIssue is Map) {
          issues.add((
            stage: rawIssue['stage']?.toString() ?? 'server_processing',
            message:
                rawIssue['message']?.toString() ??
                'The server reported an unspecified mail issue.',
            armCaseId: rawIssue['armCaseId']?.toString() ?? response.armCaseId,
          ));
        }
      }
    }
    return _InvoiceDeliveryOutcome(
      delivered: body['delivered'] == true,
      serverIssues: issues,
    );
  }

  String _readableClientMailError(Object error) {
    final message = error.toString().trim();
    return message.isEmpty
        ? 'The client encountered an unknown invoice mailing error.'
        : message.replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '');
  }

  InvoiceMailIssueRepository get _invoiceMailIssueRepository =>
      InvoiceMailIssueRepository(firestore);

  Future<void> _recordInvoiceMailIssue(InvoiceMailIssue issue) async {
    try {
      await _invoiceMailIssueRepository.record(issue);
    } catch (error, stackTrace) {
      debugPrint('Could not persist invoice mail issue: $error\n$stackTrace');
      try {
        await armClient.captureException(
          error: error,
          stackTrace: stackTrace,
          feature: 'invoicing',
          operation: 'persist_invoice_mail_issue',
          severity: ArmSeverity.serious,
          category: 'data_write',
          tags: <String, dynamic>{'invoiceId': issue.invoiceId},
          handled: true,
        );
      } catch (_) {}
    }
  }

  void _showInvoiceMailProgressSnackBar(
    InvoiceMailBatchController controller,
  ) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 365),
        showCloseIcon: true,
        content: InvoiceMailProgressContent(
          controller: controller,
          onInfo: () => _showInvoiceMailIssuesDialog(
            controller.value.issues,
            includeResolve: false,
          ),
        ),
      ),
    );
  }

  Future<void> _showHistoricalMailIssuesDialog() async {
    try {
      final issues = await _invoiceMailIssueRepository.loadOutstanding();
      if (!mounted) return;
      await _showInvoiceMailIssuesDialog(issues, includeResolve: true);
    } catch (error, stackTrace) {
      String? caseId;
      try {
        final capture = await armClient.captureException(
          error: error,
          stackTrace: stackTrace,
          feature: 'invoicing',
          operation: 'load_invoice_mail_issues',
          severity: ArmSeverity.moderate,
          category: 'data_read',
          handled: true,
        );
        caseId = capture.caseId;
      } catch (_) {}
      if (mounted) {
        showArmSnackBar(
          context,
          'Invoice mailing issues could not be loaded.',
          caseId: caseId,
        );
      }
    }
  }

  Future<void> _showInvoiceMailIssuesDialog(
    List<InvoiceMailIssue> initialIssues, {
    required bool includeResolve,
  }) async {
    if (!mounted) return;
    final issues = List<InvoiceMailIssue>.of(initialIssues);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => InvoiceMailIssuesDialog(
          issues: issues,
          onClose: () => Navigator.of(dialogContext).pop(),
          onResolve: includeResolve
              ? (issue) async {
                  final documentId = issue.documentId;
                  if (documentId == null) return;
                  await _invoiceMailIssueRepository.resolve(
                    issue,
                    resolvedBy: auth.currentUser?.email,
                  );
                  issues.remove(issue);
                  setDialogState(() {});
                }
              : null,
        ),
      ),
    );
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
        teachersInvoiceCache.registry[docRef.id] = await docRef.get();

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
