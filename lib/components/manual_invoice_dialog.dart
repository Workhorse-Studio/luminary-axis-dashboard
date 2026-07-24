part of axis_dashboard;

typedef ManualInvoiceSendCallback =
    Future<bool> Function(StudentData student, StudentInvoiceData invoice);

typedef _ManualInvoiceEntryControllers = ({
  TextEditingController description,
  TextEditingController quantity,
  TextEditingController amount,
});

StudentInvoiceData createManualStudentInvoice({
  required StudentData student,
  required List<InvoiceEntry> entries,
  DateTime? generatedAt,
}) {
  final createdAt = generatedAt ?? DateTime.now();
  return StudentInvoiceData(
    invoiceDateFormatted: createdAt.toTimestampStringShort(),
    address: student.address,
    amtPayable: entries.fold(0, (total, entry) => total + entry.amt),
    dueDateFormatted: createdAt
        .add(const Duration(days: 7))
        .toTimestampStringShort(),
    entries: entries,
    invoiceId: 'MANUAL-${createdAt.millisecondsSinceEpoch}',
    parentName: student.parentName,
    studentName: student.name,
    invoiceStatus: InvoiceStatus.pendingPayment,
    terms: 'Custom',
  );
}

class ManualInvoiceDialog extends StatefulWidget {
  final List<StudentData> students;
  final ManualInvoiceSendCallback onSend;

  const ManualInvoiceDialog({
    required this.students,
    required this.onSend,
    super.key,
  });

  @override
  State<ManualInvoiceDialog> createState() => _ManualInvoiceDialogState();
}

class _ManualInvoiceDialogState extends State<ManualInvoiceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<_ManualInvoiceEntryControllers> _entryControllers = [];
  final TextEditingController _studentSearchController =
      TextEditingController();
  StudentData? _selectedStudent;
  StudentInvoiceData? _preview;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _addEntry(rebuild: false);
    _studentSearchController.addListener(_handleStudentQueryChanged);
  }

  @override
  void dispose() {
    _studentSearchController
      ..removeListener(_handleStudentQueryChanged)
      ..dispose();
    for (final controllers in _entryControllers) {
      _disposeEntry(controllers);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final dialogWidth = min(1200.0, max(0.0, mediaSize.width - 48));
    final dialogHeight = max(0.0, mediaSize.height - 48);
    return Dialog(
      backgroundColor: AxisColors.blackPurple50,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AxisColors.blackPurple20),
      ),
      child: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: dialogHeight),
          child: _preview == null ? _buildDraft() : _buildPreview(_preview!),
        ),
      ),
    );
  }

  Widget _buildDraft() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manual Invoice', style: heading2),
                const SizedBox(height: 28),
                Text('Student', style: heading3),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) => DropdownMenu<StudentData>(
                    key: const ValueKey('manual-invoice-student-dropdown'),
                    controller: _studentSearchController,
                    width: constraints.maxWidth,
                    enableFilter: true,
                    enableSearch: true,
                    requestFocusOnTap: true,
                    leadingIcon: const Icon(Icons.person_search_outlined),
                    hintText: 'Search by student name',
                    textStyle: buttonLabel,
                    inputDecorationTheme: InputDecorationTheme(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AxisColors.blackPurple20,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: AxisColors.lilacPurple20,
                        ),
                      ),
                    ),
                    menuStyle: const MenuStyle(
                      side: WidgetStatePropertyAll(
                        BorderSide(color: AxisColors.blackPurple20),
                      ),
                      backgroundColor: WidgetStatePropertyAll(
                        AxisColors.blackPurple30,
                      ),
                    ),
                    dropdownMenuEntries: [
                      for (final student in widget.students)
                        DropdownMenuEntry<StudentData>(
                          value: student,
                          label: student.name,
                          style: menuEntryStyle,
                        ),
                    ],
                    onSelected: (student) {
                      setState(() {
                        _selectedStudent = student;
                      });
                    },
                  ),
                ),
                if (widget.students.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text('No students found.', style: body2),
                ],
                if (_selectedStudent != null) ...[
                  const SizedBox(height: 28),
                  for (int index = 0; index < _entryControllers.length; index++)
                    Padding(
                      key: ValueKey('manual-invoice-entry-$index'),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildEntryRow(index),
                    ),
                  AxisButton.text(
                    key: const ValueKey('manual-invoice-add-entry'),
                    width: 150,
                    height: 52,
                    icon: Icons.add,
                    label: 'Add Entry',
                    onPressed: _addEntry,
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AxisButton.text(
                      key: const ValueKey('manual-invoice-preview'),
                      width: 140,
                      height: 56,
                      icon: Icons.preview_outlined,
                      label: 'Preview',
                      onPressed: _showPreview,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryRow(int index) {
    final controllers = _entryControllers[index];
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: _buildEntryField(
            fieldKey: ValueKey('manual-invoice-entry-$index-description'),
            controller: controllers.description,
            label: 'Entry name',
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter an entry name'
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildEntryField(
            fieldKey: ValueKey('manual-invoice-entry-$index-quantity'),
            controller: controllers.quantity,
            label: 'Qty',
            keyboardType: TextInputType.number,
            validator: (value) {
              final quantity = int.tryParse(value?.trim() ?? '');
              return quantity == null || quantity <= 0
                  ? 'Enter a valid quantity'
                  : null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildEntryField(
            fieldKey: ValueKey('manual-invoice-entry-$index-amount'),
            controller: controllers.amount,
            label: 'Amount',
            prefixText: r'$ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final amount = _parseAmount(value);
              return amount == null || amount <= 0
                  ? 'Enter a valid amount'
                  : null;
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            key: ValueKey('manual-invoice-entry-$index-remove'),
            tooltip: 'Remove entry',
            onPressed: _entryControllers.length == 1
                ? null
                : () => _removeEntry(index),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 680
          ? row
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: 680, child: row),
            ),
    );
  }

  Widget _buildEntryField({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: keyboardType,
      style: body2.copyWith(color: AxisColors.white50),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: body2,
        prefixText: prefixText,
        prefixStyle: body2.copyWith(color: AxisColors.white50),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AxisColors.blackPurple20),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AxisColors.lilacPurple20),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildPreview(StudentInvoiceData invoice) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StudentInvoiceWidget(
            studentInvoiceData: invoice,
            total: invoice.amtPayable,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AxisButton.text(
                key: const ValueKey('manual-invoice-edit-draft'),
                width: 150,
                height: 56,
                icon: Icons.edit_outlined,
                label: 'Edit Draft',
                onPressed: _isSending
                    ? null
                    : () => setState(() => _preview = null),
              ),
              const SizedBox(width: 16),
              _isSending
                  ? const SizedBox(
                      width: 150,
                      height: 56,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : AxisButton.text(
                      key: const ValueKey('manual-invoice-send'),
                      width: 150,
                      height: 56,
                      icon: Icons.send,
                      label: 'Send',
                      onPressed: _send,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  void _addEntry({bool rebuild = true}) {
    final controllers = (
      description: TextEditingController(),
      quantity: TextEditingController(text: '1'),
      amount: TextEditingController(),
    );
    if (rebuild) {
      setState(() => _entryControllers.add(controllers));
    } else {
      _entryControllers.add(controllers);
    }
  }

  void _removeEntry(int index) {
    final removed = _entryControllers.removeAt(index);
    _disposeEntry(removed);
    setState(() {});
  }

  void _disposeEntry(_ManualInvoiceEntryControllers controllers) {
    controllers.description.dispose();
    controllers.quantity.dispose();
    controllers.amount.dispose();
  }

  void _showPreview() {
    final entriesValid = _formKey.currentState?.validate() ?? false;
    if (_selectedStudent == null || !entriesValid) return;

    final entries = [
      for (final controllers in _entryControllers)
        if (_parseAmount(controllers.amount.text) case final double amount)
          (
            desc: controllers.description.text.trim(),
            qty: int.parse(controllers.quantity.text.trim()),
            rate: amount / int.parse(controllers.quantity.text.trim()),
            amt: amount,
          ),
    ];
    setState(() {
      _preview = createManualStudentInvoice(
        student: _selectedStudent!,
        entries: entries,
      );
    });
  }

  Future<void> _send() async {
    final preview = _preview;
    final student = _selectedStudent;
    if (preview == null || student == null || _isSending) return;

    setState(() => _isSending = true);
    final sent = await widget.onSend(student, preview);
    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isSending = false);
    }
  }

  double? _parseAmount(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', ''));

  void _handleStudentQueryChanged() {
    final student = _selectedStudent;
    if (student != null && _studentSearchController.text != student.name) {
      setState(() {
        _selectedStudent = null;
        _preview = null;
      });
    }
  }
}
