part of digistore;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (ctx) => auth_ui.SignInScreen(
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
              if (!(await isUserAdmin())) {
                wing = userData!['wing'];
              }
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
