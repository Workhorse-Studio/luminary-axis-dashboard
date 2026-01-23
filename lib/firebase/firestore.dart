part of digistore;

final firestore = kDebugMode
    ? (FirebaseFirestore.instance..useFirestoreEmulator('127.0.0.1', 8080))
    : FirebaseFirestore.instance;
