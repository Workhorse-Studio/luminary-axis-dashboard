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
  late final List<InvoiceEntry> entries;
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
        (widget.teacherInvoiceData!.dueDateFormatted);
    entries =
        (widget.studentInvoiceData?.entries) ??
        (widget.teacherInvoiceData!.entries);
    for (final e in entries) {
      controllers.add((
        descController: TextEditingController(text: e.desc),
        qtyController: TextEditingController(text: e.qty.toString()),
        rateController: TextEditingController(text: e.rate.toStringAsFixed(2)),
      ));
    }
    super.initState();
  }

  @override
  void dispose() {
    dueDateController.dispose();
    for (final controllerGroup in controllers) {
      controllerGroup.descController.dispose();
      controllerGroup.qtyController.dispose();
      controllerGroup.rateController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStudentInvoice = studentInvoiceData;
    final currentTeacherInvoice = teacherInvoiceData;
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double horizontalPadding = constraints.maxWidth > 1440
              ? 48
              : 24;
          final double verticalPadding = constraints.maxHeight > 900 ? 32 : 20;
          final double maxDialogWidth = min(
            constraints.maxWidth - horizontalPadding * 2,
            1200,
          );
          final double maxDialogHeight =
              constraints.maxHeight - verticalPadding * 2;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxDialogWidth,
                maxHeight: maxDialogHeight,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: currentStudentInvoice != null
                    ? StudentInvoiceWidget(
                        key: ValueKey(
                          entries.map(
                            (e) => "${e.desc}-${e.amt}-${e.qty}-${e.rate}",
                          ),
                        ),
                        studentInvoiceData: currentStudentInvoice,
                        total: total,
                        descriptionFieldBuilder: _buildDescriptionField,
                        quantityFieldBuilder: _buildQuantityField,
                        rateFieldBuilder: _buildRateField,
                      )
                    : TeacherInvoiceWidget(
                        key: ValueKey(
                          entries.map(
                            (e) => "${e.desc}-${e.amt}-${e.qty}-${e.rate}",
                          ),
                        ),
                        teacherInvoiceData: currentTeacherInvoice!,
                        total: total,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateEntryAndTotal(int index, InvoiceEntry newEntry) {
    entries[index] = newEntry;
    total = entries.fold(0.0, (acc, item) => acc + item.amt);
    setState(() {});
    updateInvoice(entries);
  }

  Widget _buildDescriptionField(
    BuildContext context,
    int index,
    InvoiceEntry entry,
  ) => _buildTableField(
    controller: controllers[index].descController,
    onChanged: (value) {
      _updateEntryAndTotal(index, (
        qty: entry.qty,
        amt: entry.amt,
        rate: entry.rate,
        desc: value,
      ));
    },
  );

  Widget _buildQuantityField(
    BuildContext context,
    int index,
    InvoiceEntry entry,
  ) => _buildTableField(
    controller: controllers[index].qtyController,
    textAlign: TextAlign.right,
    keyboardType: TextInputType.number,
    onChanged: (value) {
      final int parsedQty = int.tryParse(value) ?? 0;
      _updateEntryAndTotal(index, (
        qty: parsedQty,
        amt: parsedQty * entry.rate,
        rate: entry.rate,
        desc: entry.desc,
      ));
    },
  );

  Widget _buildRateField(
    BuildContext context,
    int index,
    InvoiceEntry entry,
  ) => _buildTableField(
    controller: controllers[index].rateController,
    textAlign: TextAlign.right,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (value) {
      final double parsedRate = double.tryParse(value) ?? 0.0;
      _updateEntryAndTotal(index, (
        qty: entry.qty,
        amt: parsedRate * entry.qty,
        rate: parsedRate,
        desc: entry.desc,
      ));
    },
  );

  Widget _buildTableField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextAlign textAlign = TextAlign.left,
    TextInputType? keyboardType,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: TextField(
            controller: controller,
            style: body3,
            textAlign: textAlign,
            keyboardType: keyboardType,
            maxLines: 1,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        );
      },
    );
  }

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
    List<InvoiceEntry> updatedEntries,
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
    if (!mounted) return;
    await showSnackbar(context);
  }
}
