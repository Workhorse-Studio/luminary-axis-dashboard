part of axis_dashboard;

class DevScreen extends StatelessWidget {
  const DevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Page Title Yeah',
      body: (_) => Center(
        child: SingleChildScrollView(
          child: TeacherInvoiceWidget(
            teacherInvoiceData: TeacherInvoiceData(
              invoiceDateFormatted: 'invoiceDateFormatted',
              address: 'address',
              amtDue: 200,
              dueDateFormatted: 'dueDate',
              invoiceStatus: InvoiceStatus.paymentReceived,
              entries: [],
              invoiceId: 'invoiceId',
              agencyName: 'Name Tutoring Services',
              teacherName: 'teacherName',
              addressLine1: 'Address Line 1',
              addressLine2: 'Address Line 2',
              phoneNum: '1234 565678',
              email: 'email@gmail.com',
            ),
            total: 200,
          ),
        ),
      ),
    );
  }
}
