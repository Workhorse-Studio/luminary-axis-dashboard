part of axis_dashboard;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => auth_ui.SignInScreen(
          providers: [auth_ui.EmailAuthProvider()],
          actions: [
            auth_ui.AuthStateChangeAction<auth_ui.SignedIn>((
              context,
              state,
            ) async {
              if ((await loadUser()) != null && context.mounted) {
                if (!await Navigator.of(context).maybePop()) {
                  Navigator.of(context).pushNamed(Routes.dashboard.slug);
                }
              }
            }),
          ],
        ),
      ),
    );
  }
}
