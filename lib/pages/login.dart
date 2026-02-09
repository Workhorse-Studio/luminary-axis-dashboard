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
              final userData =
                  (await firestore
                          .collection('users')
                          .doc(auth.currentUser!.uid)
                          .get())
                      .data();
              if (userData != null) {
                role = userData['role'];
                isAdmin = role == 'admin';
                if (isAdmin) role = 'teacher';
                if (context.mounted) {
                  if (!await Navigator.of(context).maybePop()) {
                    Navigator.of(context).pushNamed(Routes.dashboard.slug);
                  }
                }
              } else {
                final onboardingData = await firestore
                    .collection('global')
                    .doc('state')
                    .collection('pendingOnboarding')
                    .where(
                      'email',
                      isEqualTo: state.user?.email,
                    )
                    .get();
                if (onboardingData.docs.isEmpty) {
                  await showDialog(
                    context: context,
                    builder: (_) => Center(
                      child: Text('No user found'),
                    ),
                  );
                } else {
                  final data = OnboardingStudentData.fromJson(
                    onboardingData.docs.first.data(),
                  );
                  final studentData = StudentData(
                    role: role = 'student',
                    email: auth.currentUser!.email!,
                    name: data.studentName,
                    studentContactNo: data.studentContactNo,
                    parentContactNo: data.parentContactNo,
                    parentName: data.parentName,
                    initialSessionCount: {data.classId: 0},
                  );
                  final docRef = firestore
                      .collection(
                        'users',
                      )
                      .doc(auth.currentUser!.uid);
                  await docRef.set(
                    studentData.toJson(),
                  );
                  await firestore
                      .collection('global')
                      .doc('state')
                      .collection('pendingOnboarding')
                      .doc(onboardingData.docs.first.id)
                      .delete();
                  if (context.mounted) {
                    if (!await Navigator.of(context).maybePop()) {
                      Navigator.of(context).pushNamed(Routes.dashboard.slug);
                    }
                  }
                }
              }
            }),
          ],
        ),
      ),
    );
  }
}
