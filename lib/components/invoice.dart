part of axis_dashboard;

class InvoiceWidget extends StatelessWidget {
  final bool maskEditableFields;
  final StudentInvoiceData? studentInvoiceData;
  final TeacherInvoiceData? teacherInvoiceData;
  final double total;
  final bool showFonts;

  const InvoiceWidget({
    this.studentInvoiceData,
    this.teacherInvoiceData,
    this.showFonts = true,
    required this.total,
    this.maskEditableFields = false,
    super.key,
  });

  TextStyle handleFonts(TextStyle style) =>
      showFonts ? style : style.copyWith(fontFamily: 'Helvetica');

  @override
  Widget build(BuildContext context) {
    final double total = studentInvoiceData == null
        ? teacherInvoiceData!.amtDue
        : studentInvoiceData!.amtPayable;
    final List<DataRow> invoiceRows = [];
    final List<({String desc, int qty, double rate, double amt})>
    invoiceEntries = studentInvoiceData == null
        ? teacherInvoiceData!.entries
        : studentInvoiceData!.entries;
    for (int i = 0; i < invoiceEntries.length; i++) {
      invoiceRows.add(
        DataRow(
          cells: [
            DataCell(
              Text(
                (i + 1).toString(),
                style: handleFonts(body3),
              ),
            ),
            DataCell(
              Text(
                invoiceEntries[i].desc,
                style: handleFonts(body3),
              ),
            ),
            DataCell(
              Text(
                maskEditableFields
                    ? ''
                    : invoiceEntries[i].qty.toStringAsFixed(2),
                style: handleFonts(body3),
              ),
            ),
            DataCell(
              Text(
                maskEditableFields
                    ? ''
                    : invoiceEntries[i].rate.toStringAsFixed(2),
                style: handleFonts(body3),
              ),
            ),
            DataCell(
              Text(
                invoiceEntries[i].amt.toStringAsFixed(2),
                style: handleFonts(body3),
              ),
            ),
          ],
        ),
      );
    }
    return Material(
      color: Color.fromARGB(255, 255, 255, 255),
      child: Padding(
        padding: const EdgeInsetsGeometry.only(
          left: 40,
          right: 40,
          top: 80,
          bottom: 80,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'images/axis_logo.png',
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
                      if (studentInvoiceData != null)
                        Text(
                          '${studentInvoiceData!.parentName} (Child: ${studentInvoiceData!.studentName})',
                          style: handleFonts(
                            body3.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 5),
                      if (studentInvoiceData != null)
                        Text(
                          studentInvoiceData!.address,
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
                      if (studentInvoiceData != null)
                        Text(
                          '# ${studentInvoiceData!.invoiceId}',
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
                      if (studentInvoiceData != null)
                        Text(
                          'SGD ${studentInvoiceData!.amtPayable.toStringAsFixed(2)}',
                          style: handleFonts(
                            body3.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 100),
                      if (studentInvoiceData != null) ...[
                        for (final line in [
                          'Invoice Date: ${studentInvoiceData!.invoiceDateFormatted.padLeft(40, ' ')}',
                          'Terms:    ${studentInvoiceData!.terms.padLeft(40, ' ')}',
                          'Due Date: ${studentInvoiceData!.dueDateFormatted.padLeft(40, ' ')}',
                        ]) ...[
                          Text(
                            line,
                            style: handleFonts(body3),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 5),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

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
              ...[
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
                  padding: const EdgeInsetsGeometry.only(right: 22),
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
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
