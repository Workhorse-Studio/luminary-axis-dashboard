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

  @override
  Widget build(BuildContext context) {
    return _InvoiceTemplate(
      maskEditableFields: maskEditableFields,
      showFonts: showFonts,
      showTopHeader: showTopHeader,
      showBottomFooter: showBottomFooter,
      startIndex: startIndex,
      total: total,
      invoiceId: teacherInvoiceData.invoiceId,
      recipientName: teacherInvoiceData.teacherName,
      address: '',
      invoiceDateFormatted: teacherInvoiceData.invoiceDateFormatted,
      terms: teacherInvoiceData.terms,
      paymentDateLabel: 'Paid Date',
      paymentDateFormatted: teacherInvoiceData.paidDateFormatted,
      entries: overrideEntries ?? teacherInvoiceData.entries,
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
