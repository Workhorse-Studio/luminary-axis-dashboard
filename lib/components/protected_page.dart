part of axis_dashboard;

class ProtectedPage extends StatefulWidget {
  final List<String> requiredRoles;
  final Routes redirectOnIncorrectRole;
  final Widget child;
  const ProtectedPage({
    required this.child,
    required this.requiredRoles,
    required this.redirectOnIncorrectRole,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => ProtectedPageState();
}

class ProtectedPageState extends State<ProtectedPage> {
  late final sub = auth.authStateChanges().listen((state) {
    checkAuthValidity();
  });

  @override
  void didChangeDependencies() {
    checkAuthValidity();

    super.didChangeDependencies();
  }

  void checkAuthValidity() {
    if (auth.currentUser == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed(Routes.login.slug);
      });
    } else if (!widget.requiredRoles.contains(role)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed(widget.redirectOnIncorrectRole.slug);
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
    await sub.cancel();
    super.dispose();
  }
}
