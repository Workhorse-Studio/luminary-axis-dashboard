part of digistore;

final auth = kDebugMode
    ? (FirebaseAuth.instance..useAuthEmulator('127.0.0.1', 8081))
    : FirebaseAuth.instance;

Future<bool> isUserAdmin() async {
  final token = await auth.currentUser!.getIdTokenResult();
  return token.claims!.containsKey('role') && token.claims!['role'] == 'admin';
}
