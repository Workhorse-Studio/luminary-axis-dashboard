part of axis_dashboard;

class StudentInvoiceWidget extends StatelessWidget {
  final bool maskEditableFields;
  final StudentInvoiceData studentInvoiceData;
  final List<InvoiceEntry>? overrideEntries;
  final double total;
  final bool showFonts;
  final bool showTopHeader;
  final bool showBottomFooter;
  final int startIndex;

  const StudentInvoiceWidget({
    required this.studentInvoiceData,
    this.overrideEntries,
    this.showFonts = true,
    this.showTopHeader = true,
    this.showBottomFooter = true,
    this.startIndex = 0,
    required this.total,
    this.maskEditableFields = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _InvoiceTemplate(
      maskEditableFields: maskEditableFields,
      showFonts: showFonts,
      showTopHeader: showTopHeader,
      showBottomFooter: showBottomFooter,
      startIndex: startIndex,
      total: total,
      invoiceId: studentInvoiceData.invoiceId,
      recipientName:
          '${studentInvoiceData.parentName} (Child: ${studentInvoiceData.studentName})',
      address: studentInvoiceData.address,
      invoiceDateFormatted: studentInvoiceData.invoiceDateFormatted,
      terms: studentInvoiceData.terms,
      paymentDateLabel: 'Due Date',
      paymentDateFormatted: studentInvoiceData.dueDateFormatted,
      entries: overrideEntries ?? studentInvoiceData.entries,
    );
  }
}

class TeacherInvoiceWidget extends StatelessWidget {
  final bool maskEditableFields;
  final TeacherInvoiceData teacherInvoiceData;
  final List<InvoiceEntry>? overrideEntries;
  final double total;
  final bool showFonts;
  final bool showTopHeader;
  final bool showBottomFooter;
  final int startIndex;

  const TeacherInvoiceWidget({
    required this.teacherInvoiceData,
    this.overrideEntries,
    this.showFonts = true,
    this.showTopHeader = true,
    this.showBottomFooter = true,
    this.startIndex = 0,
    required this.total,
    this.maskEditableFields = false,
    super.key,
  });

  TextStyle handleFonts(TextStyle style) =>
      showFonts ? style : style.copyWith(fontFamily: 'Helvetica');

  @override
  Widget build(BuildContext context) {
    final displayEntries = overrideEntries ?? teacherInvoiceData.entries;
    final issuerLines = <String>{
      teacherInvoiceData.agencyName,
      teacherInvoiceData.addressLine1,
      teacherInvoiceData.addressLine2,
      teacherInvoiceData.phoneNum,
      teacherInvoiceData.email,
    }.where((line) => line.trim().isNotEmpty).toList();
    final billToLines = <String>{
      teacherInvoiceData.teacherName,
      teacherInvoiceData.address,
      teacherInvoiceData.addressLine1,
      teacherInvoiceData.addressLine2,
      teacherInvoiceData.phoneNum,
      teacherInvoiceData.email,
    }.where((line) => line.trim().isNotEmpty).toList();
    final effectiveBillToLines = billToLines.isEmpty
        ? issuerLines
        : billToLines;

    TableCell buildCell(
      String text, {
      TextAlign textAlign = TextAlign.left,
      bool isHeader = false,
      bool isAmount = false,
    }) {
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            text,
            textAlign: textAlign,
            style: handleFonts(
              (isHeader
                      ? body3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AxisColors.blackPurple50,
                        )
                      : body3)
                  .copyWith(
                    fontWeight: isAmount ? FontWeight.w600 : null,
                    color: AxisColors.blackPurple50,
                  ),
            ),
          ),
        ),
      );
    }

    final List<TableRow> invoiceRows = [
      TableRow(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF0F5B73), width: 1.5),
            bottom: BorderSide(color: Color(0xFF0F5B73), width: 1.5),
          ),
        ),
        children: [
          buildCell('Sessions', isHeader: true),
          buildCell('Description', isHeader: true),
          buildCell('Rate', isHeader: true, textAlign: TextAlign.right),
          buildCell('Amount', isHeader: true, textAlign: TextAlign.right),
        ],
      ),
    ];

    for (int i = 0; i < displayEntries.length; i++) {
      final entry = displayEntries[i];
      invoiceRows.add(
        TableRow(
          decoration: BoxDecoration(
            color: i.isEven ? const Color(0xFFE5E5E5) : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFF0F5B73), width: 1.2),
            ),
          ),
          children: [
            buildCell(entry.qty.toString()),
            buildCell(entry.desc),
            buildCell(
              '\$${entry.rate.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
            ),
            buildCell(
              '\$${entry.amt.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              isAmount: true,
            ),
          ],
        ),
      );
    }

    final int blankRowCount = displayEntries.length >= 6
        ? 0
        : 6 - displayEntries.length;
    for (int i = 0; i < blankRowCount; i++) {
      final bool useGrey = (displayEntries.length + i).isEven;
      invoiceRows.add(
        TableRow(
          decoration: BoxDecoration(
            color: useGrey ? const Color(0xFFE5E5E5) : Colors.white,
            border: const Border(
              bottom: BorderSide(color: Color(0xFF0F5B73), width: 1.2),
            ),
          ),
          children: [
            buildCell(''),
            buildCell(''),
            buildCell('', textAlign: TextAlign.right),
            buildCell('', textAlign: TextAlign.right),
          ],
        ),
      );
    }

    return Material(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 28,
          right: 28,
          top: 24,
          bottom: 36,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTopHeader) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                color: const Color(0xFF0F5B73),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'INVOICE',
                        style: handleFonts(
                          heading1.copyWith(
                            fontSize: 54,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final line in issuerLines) ...[
                            Text(
                              line,
                              textAlign: TextAlign.right,
                              style: handleFonts(
                                body3.copyWith(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight:
                                      line == teacherInvoiceData.agencyName
                                      ? FontWeight.w700
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice No.',
                          style: handleFonts(
                            body3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AxisColors.blackPurple50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Date of Issue',
                          style: handleFonts(
                            body3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AxisColors.blackPurple50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Due Date',
                          style: handleFonts(
                            body3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AxisColors.blackPurple50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacherInvoiceData.invoiceId,
                          style: handleFonts(body3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teacherInvoiceData.invoiceDateFormatted,
                          style: handleFonts(body3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teacherInvoiceData.dueDateFormatted,
                          style: handleFonts(body3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Bill To',
                          style: handleFonts(
                            body3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AxisColors.blackPurple50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final line in effectiveBillToLines) ...[
                          Text(
                            line,
                            textAlign: TextAlign.right,
                            style: handleFonts(
                              body3.copyWith(
                                color: AxisColors.blackPurple50,
                                decoration: line.contains('@')
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.1),
                1: FlexColumnWidth(2.8),
                2: FlexColumnWidth(1.1),
                3: FlexColumnWidth(1.1),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                verticalInside: BorderSide(color: Color(0xFFD8D8D8)),
              ),
              children: invoiceRows,
            ),
            const SizedBox(height: 24),
            if (showBottomFooter) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Signature',
                        style: handleFonts(
                          body3.copyWith(
                            color: AxisColors.blackPurple50,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final row in [
                          ('Subtotal', total),
                          ('Discount', 0.0),
                          ('Tax Rate', 0.0),
                          ('Tax', 0.0),
                        ]) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.$1,
                                    textAlign: TextAlign.right,
                                    style: handleFonts(
                                      body3.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AxisColors.blackPurple50,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 88,
                                  child: Text(
                                    row.$1 == 'Tax Rate'
                                        ? '${row.$2.toStringAsFixed(0)}%'
                                        : '\$${row.$2.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: handleFonts(
                                      body3.copyWith(
                                        color: AxisColors.blackPurple50,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: AxisColors.blackPurple50,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total',
                                  textAlign: TextAlign.right,
                                  style: handleFonts(
                                    body3.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AxisColors.blackPurple50,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 88,
                                child: Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: handleFonts(
                                    body3.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AxisColors.blackPurple50,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceTemplate extends StatelessWidget {
  final bool maskEditableFields;
  final List<InvoiceEntry> entries;
  final double total;
  final bool showFonts;
  final bool showTopHeader;
  final bool showBottomFooter;
  final int startIndex;
  final String invoiceId;
  final String recipientName;
  final String address;
  final String invoiceDateFormatted;
  final String terms;
  final String paymentDateLabel;
  final String paymentDateFormatted;

  const _InvoiceTemplate({
    required this.maskEditableFields,
    required this.entries,
    required this.total,
    required this.showFonts,
    required this.showTopHeader,
    required this.showBottomFooter,
    required this.startIndex,
    required this.invoiceId,
    required this.recipientName,
    required this.address,
    required this.invoiceDateFormatted,
    required this.terms,
    required this.paymentDateLabel,
    required this.paymentDateFormatted,
  });

  TextStyle handleFonts(TextStyle style) =>
      showFonts ? style : style.copyWith(fontFamily: 'Helvetica');

  @override
  Widget build(BuildContext context) {
    final List<DataRow> invoiceRows = [];
    for (int i = 0; i < entries.length; i++) {
      invoiceRows.add(
        DataRow(
          cells: [
            DataCell(
              Text(
                (startIndex + i + 1).toString(),
                style: handleFonts(body3),
              ),
            ),
            DataCell(
              Text(
                entries[i].desc,
                style: handleFonts(body3),
              ),
            ),
            DataCell(
              Text(
                maskEditableFields ? '' : entries[i].qty.toStringAsFixed(2),
                style: handleFonts(body3),
              ),
            ),
            DataCell(
              Text(
                maskEditableFields ? '' : entries[i].rate.toStringAsFixed(2),
                style: handleFonts(body3),
              ),
            ),
            DataCell(
              Text(
                entries[i].amt.toStringAsFixed(2),
                style: handleFonts(body3),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 40,
          right: 40,
          top: 80,
          bottom: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showTopHeader) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/axis_logo.png',
                        width: 300,
                        height: 100,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Axis Education Centre',
                        style: handleFonts(
                          heading2.copyWith(
                            color: AxisColors.blackPurple50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '9 King Albert Park #02-08 598332',
                        style: handleFonts(body3),
                      ),
                      const SizedBox(height: 5),
                      Text('80626728', style: handleFonts(body3)),
                      const SizedBox(height: 5),
                      Text(
                        'axiseducationcentre@gmail.com',
                        style: handleFonts(body3),
                      ),
                      const SizedBox(height: 100),
                      Text(
                        recipientName,
                        style: handleFonts(
                          body3.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (address.isNotEmpty)
                        Text(
                          address,
                          style: handleFonts(body3),
                        ),
                      const SizedBox(height: 30),
                      Text('Payment Methods:', style: handleFonts(body3)),
                      const SizedBox(height: 30),
                      ...[
                        for (final line in const [
                          '1. PayNow (UEN)',
                          'UEN: 202548151Z',
                          'Name: Axis Education Centre',
                          'Please indicate Invoice Number in the remarks.',
                        ]) ...[
                          Text(line, style: handleFonts(body3)),
                          const SizedBox(height: 5),
                        ],
                      ],
                      const SizedBox(height: 30),
                      ...[
                        for (final line in const [
                          '2. Bank Transfer',
                          'Bank: UOB Bank',
                          'Account Name: Axis Education Centre',
                          'Account Number: 7623031393',
                          'Reference: Invoice Number',
                        ]) ...[
                          Text(line, style: handleFonts(body3)),
                          const SizedBox(height: 5),
                        ],
                      ],
                    ],
                  ),
                  const Spacer(),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TAX INVOICE',
                        style: handleFonts(
                          heading1.copyWith(
                            color: AxisColors.blackPurple50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '# $invoiceId',
                        style: handleFonts(
                          heading3.copyWith(
                            color: AxisColors.blackPurple50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Balance Due',
                        style: handleFonts(
                          body3.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'SGD ${total.toStringAsFixed(2)}',
                        style: handleFonts(
                          body3.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                      for (final line in [
                        'Invoice Date: ${invoiceDateFormatted.padLeft(40, ' ')}',
                        'Terms:    ${terms.padLeft(40, ' ')}',
                        '$paymentDateLabel: ${paymentDateFormatted.padLeft(40, ' ')}',
                      ]) ...[
                        Text(
                          line,
                          style: handleFonts(body3),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 5),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
            DataTable(
              border: TableBorder(bottom: BorderSide(color: Colors.grey)),
              headingRowColor: WidgetStatePropertyAll(Colors.blueGrey),
              headingTextStyle: handleFonts(
                body3.copyWith(color: Colors.white),
              ),
              columns: [
                DataColumn(
                  label: Text('#', style: handleFonts(body3)),
                ),
                DataColumn(
                  label: Text('Description', style: handleFonts(body3)),
                  columnWidth: IntrinsicColumnWidth(flex: 1),
                ),
                DataColumn(label: Text('Qty', style: handleFonts(body3))),
                DataColumn(label: Text('Rate', style: handleFonts(body3))),
                DataColumn(label: Text('Amount', style: handleFonts(body3))),
              ],
              rows: invoiceRows,
            ),
            const SizedBox(height: 8),
            if (showBottomFooter) ...[
              Text(
                'Sub Total: ${total.toStringAsFixed(2).padLeft(30, ' ')}      ',
                style: handleFonts(body3),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Text(
                  'Total:       ${total.toStringAsFixed(2).padLeft(30, ' ')}      ',
                  style: handleFonts(
                    body3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Text(
                  'Balance Due:       ${total.toStringAsFixed(2).padLeft(30, ' ')}      ',
                  style: handleFonts(
                    body3.copyWith(fontWeight: FontWeight.bold),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 5),
            ],
          ],
        ),
      ),
    );
  }
}
