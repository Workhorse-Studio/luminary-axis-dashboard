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
  late final StreamSubscription sub;

  @override
  void initState() {
    sub = auth.authStateChanges().listen((_) {
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute =
        ModalRoute.of(context)?.settings.name ?? Routes.dashboard.slug;

    // Generate navigation items for sidebar
    final navItems = Routes.values
        .where(
          (r) =>
              !const [Routes.login, Routes.dev, Routes.students].contains(r) &&
              hasRolesForRoute(r),
        )
        .map(
          (r) => NavItem(
            label: r.label,
            icon: r.icon,
            route: r.slug,
            isNew: r == Routes.invoicing, // Example badge
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: StakentColors.bgPrimary,
      body: Row(
        children: [
          // Left Sidebar
          StakentSidebar(
            logoText: 'Stakent',
            logoTagline: 'Top Staking Assets',
            navItems: navItems,
            currentRoute: currentRoute,
            onRouteSelected: (route) {
              if (route != currentRoute) {
                Navigator.of(context).pushReplacementNamed(route);
              }
            },
            onLogout: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(Routes.login.slug);
              }
            },
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Topbar
                StakentTopbar(
                  title: widget.pageTitle,
                  userAvatarUrl: '', // Add proper avatar URL if available
                  userName: auth.currentUser?.email ?? 'Ryan Crawford',
                  userStatus: 'PRO',
                  trailing: Row(children: widget.actions),
                ),

                // Page Content
                Expanded(
                  child: Container(
                    color: StakentColors.bgPrimary,
                    child: widget.body(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }
}
