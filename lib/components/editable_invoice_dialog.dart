part of axis_dashboard;

class EditableInvoiceDialog extends StatefulWidget {
  final StudentInvoiceData? studentInvoiceData;
  final TeacherInvoiceData? teacherInvoiceData;
  const EditableInvoiceDialog({
    this.studentInvoiceData,
    this.teacherInvoiceData,
    super.key,
  });
  @override
  State<StatefulWidget> createState() => EditableInvoiceDialogState();
}

typedef RowControllerGroup = ({
  TextEditingController descController,
  TextEditingController qtyController,
  TextEditingController rateController,
});

class EditableInvoiceDialogState extends State<EditableInvoiceDialog> {
  late double total;
  final TextEditingController dueDateController = TextEditingController();
  late final List<({double amt, String desc, int qty, double rate})> entries;
  final List<RowControllerGroup> controllers = [];
  StudentInvoiceData? studentInvoiceData;
  TeacherInvoiceData? teacherInvoiceData;
  @override
  void initState() {
    studentInvoiceData = widget.studentInvoiceData;
    teacherInvoiceData = widget.teacherInvoiceData;
    total =
        (widget.studentInvoiceData?.amtPayable) ??
        (widget.teacherInvoiceData!.amtDue);
    dueDateController.text =
        (widget.studentInvoiceData?.dueDateFormatted) ??
        (widget.teacherInvoiceData!.paidDateFormatted);
    entries =
        (widget.studentInvoiceData?.entries) ??
        (widget.teacherInvoiceData!.entries);
    for (final e in entries) {
      controllers.add((
        descController: TextEditingController(text: ''),
        qtyController: TextEditingController(text: e.qty.toStringAsFixed(2)),
        rateController: TextEditingController(text: e.rate.toStringAsFixed(2)),
      ));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (int i = 0; i < entries.length; i++) {
      rows.addAll(generateFieldsWithOffset(i));
    }
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.85,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                InvoiceWidget(
                  maskEditableFields: true,
                  key: ValueKey(
                    entries.map((e) => "${e.desc}-${e.amt}-${e.qty}-${e.rate}"),
                  ),
                  studentInvoiceData: widget.studentInvoiceData,
                  teacherInvoiceData: widget.teacherInvoiceData,
                  total: total,
                ),

                ...rows,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateEntryAndTotal(int index, ({double amt, String desc, int qty, double rate}) newEntry) {
    entries[index] = newEntry;
    total = entries.fold(0.0, (acc, item) => acc + item.amt);
    setState(() {});
    updateInvoice(entries);
  }

  List<Widget> generateFieldsWithOffset(int index) => [
    Positioned(
      top: (924 + 47 * index) as double,
      right: 270,
      width: 50,
      height: 24,
      child: SizedBox(
        height: 100,
        width: 100,
        child: Center(
          child: TextField(
            controller: controllers[index].qtyController,
            style: body3,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(top: -20, left: 7),
              enabledBorder: InputBorder.none,
            ),
            onChanged: (value) async {
              int parsedQty = int.tryParse(value) ?? 0;
              _updateEntryAndTotal(index, (
                qty: parsedQty,
                amt: parsedQty * entries[index].rate,
                rate: entries[index].rate,
                desc: entries[index].desc,
              ));
            },
          ),
        ),
      ),
    ),
    Positioned(
      top: (924 + 47 * index) as double,
      right: 174,
      width: 50,
      height: 24,
      child: SizedBox(
        height: 100,
        width: 100,
        child: Center(
          child: TextField(
            controller: controllers[index].rateController,
            style: body3,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(top: -20, left: 7),
              enabledBorder: InputBorder.none,
            ),
            onChanged: (value) async {
              double parsedRate = double.tryParse(value) ?? 0.0;
              _updateEntryAndTotal(index, (
                qty: entries[index].qty,
                amt: parsedRate * entries[index].qty,
                rate: parsedRate,
                desc: entries[index].desc,
              ));
            },
          ),
        ),
      ),
    ),
    Positioned(
      top: (918 + 47 * index) as double,
      right: 400,
      width: 270,
      height: 34,
      child: SizedBox(
        height: 100,
        width: 100,
        child: Center(
          child: TextField(
            controller: controllers[index].descController,
            style: body3,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(top: -20, left: 7),
              enabledBorder: InputBorder.none,
            ),
            onChanged: (value) async {
               _updateEntryAndTotal(index, (
                qty: entries[index].qty,
                amt: entries[index].amt,
                rate: entries[index].rate,
                desc: value,
              ));
            },
          ),
        ),
      ),
    ),
  ];

  Future<void> showSnackbar(BuildContext context) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text('Changes saved. Refreshing invoice...')),
    );
    if (studentInvoiceData != null) {
      studentInvoiceData = StudentInvoiceData.fromJson(
        (await firestore
                .collection('global')
                .doc('archives')
                .collection('invoices')
                .doc(studentInvoiceData!.invoiceId)
                .get())
            .data()!,
      );
    } else {
      teacherInvoiceData = TeacherInvoiceData.fromJson(
        (await firestore
                .collection('global')
                .doc('archives')
                .collection('invoices')
                .doc(teacherInvoiceData!.invoiceId)
                .get())
            .data()!,
      );
    }
    setState(() {});
  }

  Future<void> updateInvoice(
    List<({double amt, String desc, int qty, double rate})> updatedEntries,
  ) async {
    await firestore
        .collection('global')
        .doc('archives')
        .collection('invoices')
        .doc(
          widget.studentInvoiceData?.invoiceId ??
              widget.teacherInvoiceData!.invoiceId,
        )
        .update({
          if (widget.studentInvoiceData == null)
            'amtDue': updatedEntries.fold(
              0.00,
              (a, b) => (a as double) + b.amt,
            ),
          if (widget.teacherInvoiceData == null)
            'amtPayable': updatedEntries.fold(
              0.00,
              (a, b) => (a as double) + b.amt,
            ),
          'entries': updatedEntries
              .map(
                (e) => {
                  'amt': e.amt,
                  'desc': e.desc,
                  'qty': e.qty,
                  'rate': e.rate,
                },
              )
              .toList(),
          'invoiceDateFormatted': DateTime.now().toTimestampStringShort(),
        });
    await showSnackbar(context);
  }
}
