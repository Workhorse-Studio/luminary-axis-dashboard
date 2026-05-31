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
              invoiceDateFormatted: '1 Month 2026',
              address: 'Name Tutoring Services\nEmail',
              amtDue: 150,
              dueDateFormatted: '7 Month 2026',
              invoiceStatus: InvoiceStatus.paymentReceived,
              entries: const [
                (
                  amt: 50,
                  desc: 'Mar-26',
                  qty: 1,
                  rate: 50,
                ),
                (
                  amt: 100,
                  desc: 'Apr-26',
                  qty: 2,
                  rate: 50,
                ),
              ],
              invoiceId: 'INV-2026-001',
              agencyName: 'Name Tutoring Services',
              teacherName: 'Name Tutoring Services',
              addressLine1: 'Street Address',
              addressLine2: 'City, State, Zip/Postal Code',
              phoneNum: 'Phone',
              email: 'Email',
            ),
            total: 150,
          ),
        ),
      ),
    );
  }
}
