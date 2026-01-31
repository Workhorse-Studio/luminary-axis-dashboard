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
            auth_ui.AuthStateChangeAction<auth_ui.UserCreated>((
              context,
              state,
            ) async {
              if (context.mounted) {
                if (!await Navigator.of(context).maybePop()) {
                  Navigator.of(context).pushNamed(Routes.dashboard.slug);
                }
              }
            }),
            auth_ui.AuthStateChangeAction<auth_ui.SignedIn>((
              context,
              state,
            ) async {
              final userData =
                  (await firestore
                          .collection('users')
                          .doc(auth.currentUser!.uid)
                          .get())
                      .data();
              role = userData!['role'];

              if (context.mounted) {
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
