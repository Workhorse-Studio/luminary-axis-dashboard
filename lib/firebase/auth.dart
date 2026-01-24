part of axis_dashboard;

final auth = kDebugMode
    ? (FirebaseAuth.instance..useAuthEmulator('127.0.0.1', 9099))
    : FirebaseAuth.instance;

Future<bool> isUserAdmin() async {
  final token = await auth.currentUser!.getIdTokenResult();
  return token.claims!.containsKey('role') && token.claims!['role'] == 'admin';
}
