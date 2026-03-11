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
          Text(
            studentData != null
                ? (studentData.invoiceIds.containsKey(i) ? 'Y' : '')
                : (teacherData!.invoiceIds.containsKey(i) ? 'Y' : ''),
            style: body2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return res;
  }
}
