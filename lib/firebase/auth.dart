part of axis_dashboard;

FirebaseAuth? _authOverride;
FirebaseAuth? _defaultAuth;

FirebaseAuth get auth => _authOverride ??= _defaultAuth ??= kDebugMode
    ? (FirebaseAuth.instance..useAuthEmulator('127.0.0.1', 9099))
    : FirebaseAuth.instance;

void overrideAuthForTesting(FirebaseAuth instance) {
  _authOverride = instance;
}

void resetAuthOverride() {
  _authOverride = null;
}

Future<bool> isUserAdmin() async {
  final token = await auth.currentUser!.getIdTokenResult();
  return token.claims!.containsKey('role') && token.claims!['role'] == 'admin';
}
