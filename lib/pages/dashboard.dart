part of axis_dashboard;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<StatefulWidget> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  bool hasLoaded = false;
  String name = '';

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Dashboard',
      actions: [
        RichText(
          text: TextSpan(
            text: 'powered by',
            style: body2,
            children: [
              TextSpan(
                text: '  Luminary',
                style: heading3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
      ],
      body: (_) => Align(
        alignment: Alignment.topLeft,
        child: FutureBuilderTemplate(
          future: () async {
            if (!hasLoaded) {
              name =
                  (await firestore
                          .collection('users')
                          .doc(auth.currentUser!.uid)
                          .get())
                      .data()!['name'];
              hasLoaded = true;
            }
            return name;
          }(),
          builder: (context, _) => Padding(
            padding: const EdgeInsets.only(left: 40, top: 40),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $name!',
                    style: heading2,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "You're signed in as ${isAdmin ? 'an' : 'a'} ${isAdmin ? 'admin' : role}",
                    style: body2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
