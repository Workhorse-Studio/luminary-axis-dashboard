part of axis_dashboard;

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
      backgroundColor: AxisColors.blackPurple50,
      body: Builder(builder: widget.body),
      drawer: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.22,
          decoration: BoxDecoration(
            color: AxisColors.blackPurple50,
            border: Border(
              right: BorderSide(color: AxisColors.blackPurple30Blur),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  'AXIS',
                  style: brandTitle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  'EDUCATION CENTRE',
                  style: brandSubtitle,
                ),
              ),
              const SizedBox(height: 30),
              for (final r in Routes.values)
                if (!((const [Routes.login, Routes.dev]).contains(r)) &&
                    hasRolesForRoute(r))
                  Padding(
                    padding: EdgeInsetsGeometry.only(
                      left: 16,
                      right: 16,
                      bottom: 5,
                      top: 5,
                    ),
                    child: AxisButton.text(
                      label: r.label,
                      isHighlighted:
                          r.slug == ModalRoute.of(context)?.settings.name,
                      width: double.infinity,
                      icon: r.icon,
                      onPressed: () => Navigator.of(context).pushNamed(r.slug),
                    ),
                  ),
              const Spacer(),
              Padding(
                padding: EdgeInsetsGeometry.only(
                  left: 16,
                  right: 16,
                  bottom: 5,
                  top: 5,
                ),
                child: AxisButton.text(
                  label: Routes.login.label,
                  isHighlighted:
                      Routes.login.slug ==
                      ModalRoute.of(context)?.settings.name,
                  width: double.infinity,
                  icon: Routes.login.icon,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(Routes.login.slug),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight: 80,
        actionsPadding: EdgeInsets.only(
          left: 20,
          right: 20,
        ),
        title: Text(
          widget.pageTitle,
          style: appBarTitle,
        ),
        actions: [
          ...widget.actions,
          /* auth.currentUser == null
              ? Text('Not signed in')
              : Text(
                  'Signed in as ${auth.currentUser!.email!.substring(0, 5)}${'*' * (auth.currentUser!.email!.length - 5)}',
                ),
        */
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
