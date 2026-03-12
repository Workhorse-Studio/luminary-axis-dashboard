part of axis_dashboard;

class DevScreen extends StatelessWidget {
  const DevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Page Title Yeah',
      body: (_) => Center(
        child: FutureBuilderTemplate(
          future: (() async => StudentInvoiceData.fromJson(
            (await firestore
                    .collection('global')
                    .doc('archives')
                    .collection('invoices')
                    .doc('hsgfKhsmHdEx6NJ1uHn2')
                    .get())
                .data()!,
          ))(),
          builder: (_, snapshot) => Center(
            child: SingleChildScrollView(
              child: EditableInvoiceDialog(
                studentInvoiceData: snapshot.data,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
