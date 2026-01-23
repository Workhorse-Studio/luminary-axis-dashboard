part of digistore;

class ProtectedPage extends StatefulWidget {
  final Widget child;
  const ProtectedPage({required this.child, super.key});

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
