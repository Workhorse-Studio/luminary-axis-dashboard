part of digistore;

class Navbar extends StatefulWidget {
  final WidgetBuilder body;
  final String pageTitle;
  final List<Widget> actions;

  const Navbar({
    required this.pageTitle,
    required this.body,
    this.actions = const [],
    super.key,
  });

  @override
  State<StatefulWidget> createState() => NavbarState();
}

class NavbarState extends State<Navbar> {
  late final sub;

  @override
  void initState() {
    sub = auth.authStateChanges().listen((_) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: widget.body),
      drawer: Drawer(
        child: Column(
          children: [
            for (final r in Routes.values)
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(r.slug),
                child: Text(
                  r.name,
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(widget.pageTitle),
        actions: [
          ...widget.actions,
          auth.currentUser == null
              ? Text('Not signed in')
              : Text(
                  'Signed in as ${auth.currentUser!.email!.substring(0, 5)}${'*' * (auth.currentUser!.email!.length - 5)}',
                ),
        ],
        leading: Builder(
          builder: (ctx) => DrawerButton(
            onPressed: () {
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() async {
    await sub.cancel();
    super.dispose();
  }
}
