part of digistore;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<StatefulWidget> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool hasLoaded = false;
  List<QueryDocumentSnapshot> snapshots = [];

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Dashboard UI',
      body: (_) => Center(
        child: SingleChildScrollView(child: Column(children: [])),
      ),
    );
  }
}
