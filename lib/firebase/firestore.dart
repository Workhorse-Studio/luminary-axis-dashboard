part of axis_dashboard;

FirebaseFirestore? _firestoreOverride;
FirebaseFirestore? _defaultFirestore;

FirebaseFirestore get firestore =>
    _firestoreOverride ??= _defaultFirestore ??= kDebugMode
    ? (FirebaseFirestore.instance..useFirestoreEmulator('127.0.0.1', 8080))
    : FirebaseFirestore.instance;

/// Replaces remote services for hermetic integration and functional tests.
///
/// Keeping this seam here prevents tests from ever connecting to production or
/// a developer's emulator by accident.
void overrideFirestoreForTesting(FirebaseFirestore instance) {
  _firestoreOverride = instance;
}

void resetFirestoreOverride() {
  _firestoreOverride = null;
}
