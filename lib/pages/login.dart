part of axis_dashboard;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: AxisColors.blackPurple50,
        appBarTheme: const AppBarTheme(
          backgroundColor: AxisColors.blackPurple50,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: AxisColors.blackPurple30.withValues(alpha: 0.3),
          filled: true,
          labelStyle: body2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AxisColors.blackPurple20),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AxisColors.blackPurple20),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AxisColors.lilacPurple20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return AxisColors.blackPurple30.withValues(alpha: 0.8);
              }
              return AxisColors.blackPurple30;
            }),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AxisColors.blackPurple20),
              ),
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(18)),
            textStyle: WidgetStatePropertyAll(
              buttonLabel.copyWith(color: AxisColors.white50),
            ),
            foregroundColor: const WidgetStatePropertyAll(AxisColors.white50),
            overlayColor: WidgetStatePropertyAll(
              AxisColors.lilacPurple20.withValues(alpha: 0.1),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: const WidgetStatePropertyAll(
              AxisColors.lilacPurple20,
            ),
            textStyle: WidgetStatePropertyAll(
              body2.copyWith(fontWeight: FontWeight.bold),
            ),
            overlayColor: WidgetStatePropertyAll(
              AxisColors.lilacPurple20.withValues(alpha: 0.1),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AxisColors.blackPurple20),
              ),
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(18)),
            foregroundColor: const WidgetStatePropertyAll(AxisColors.white50),
            overlayColor: WidgetStatePropertyAll(
              AxisColors.lilacPurple20.withValues(alpha: 0.1),
            ),
          ),
        ),
        textTheme: TextTheme(
          headlineSmall: heading1,
          titleMedium: body3.copyWith(color: AxisColors.white50),
          bodyLarge: body2.copyWith(
            color: AxisColors.lilacPurple20.withValues(
              alpha: 0.5,
            ),
          ),
          bodySmall: body2.copyWith(
            color: AxisColors.lilacPurple20.withValues(
              alpha: 0.5,
            ),
          ),
        ),
      ),
      child: auth_ui.SignInScreen(
        providers: [auth_ui.EmailAuthProvider()],
        headerBuilder: (context, constraints, shrinkOffset) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset('assets/images/axis_logomark.png'),
            ),
          );
        },
        subtitleBuilder: (context, action) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: action == auth_ui.AuthAction.signIn
                ? Text(
                    'Welcome to Axis Dashboard, please sign in!',
                    style: body2,
                  )
                : Text(
                    'Welcome to Axis Dashboard, please sign up!',
                    style: body2,
                  ),
          );
        },

        actions: [
          auth_ui.AuthStateChangeAction<auth_ui.SignedIn>((
            context,
            state,
          ) async {
            final userData = await loadUser();
            if (userData != null && context.mounted) {
              final router = Navigator.of(context);
              if (!await router.maybePop()) {
                router.pushNamed(Routes.dashboard.slug);
              }
            } else if (context.mounted) {
              await armClient.captureException(
                error: StateError(
                  'Authenticated user has no Firestore profile at their Auth UID',
                ),
                stackTrace: StackTrace.current,
                feature: 'authentication',
                operation: 'load_user_profile',
                severity: ArmSeverity.serious,
                category: 'identity',
                handled: true,
              );
              await auth.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Your account is authenticated but has not been provisioned for Axis Dashboard. Please contact an administrator.',
                    ),
                  ),
                );
              }
            }
          }),
        ],
      ),
    );
  }
}
