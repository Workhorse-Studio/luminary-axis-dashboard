part of axis_dashboard;

class ProtectedPage extends StatefulWidget {
  final Routes redirectOnIncorrectRole;
  final Widget child;
  const ProtectedPage({
    required this.child,
    required this.redirectOnIncorrectRole,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => ProtectedPageState();
}

class ProtectedPageState extends State<ProtectedPage> {
  @override
  void didChangeDependencies() {
    checkAuthValidity();

    super.didChangeDependencies();
  }


  void checkAuthValidity() {
    final String routeName = ModalRoute.of(context)!.settings.name!;
    if (auth.currentUser == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.name != Routes.login.slug) {
          Navigator.of(context).pushNamed(Routes.login.slug);
        }
      });
    } else if (!hasRolesForRoute(
      Routes.values.where((route) => route.slug == routeName).first,
    )) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (routeName != widget.redirectOnIncorrectRole.slug) {
          Navigator.of(context).pushNamed(widget.redirectOnIncorrectRole.slug);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    checkAuthValidity();
    return widget.child;
  }

  @override
  void dispose() async {
    super.dispose();
  }
}
