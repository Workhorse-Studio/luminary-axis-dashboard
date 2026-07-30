import 'package:axis_dashboard/main.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore db;

  setUp(() {
    db = FakeFirebaseFirestore();
    overrideFirestoreForTesting(db);
    overrideAuthForTesting(
      MockFirebaseAuth(
        mockUser: MockUser(uid: 'admin-1', email: 'admin@example.com'),
        signedIn: true,
      ),
    );
    role = '';
    isAdmin = false;
  });

  tearDown(() {
    resetFirestoreOverride();
    resetAuthOverride();
  });

  test(
    'loads a dashboard profile only from the Firebase Auth UID document',
    () async {
      await db.collection('users').doc('admin-1').set({
        'role': 'admin',
        'name': 'UID-backed Admin',
        'email': 'admin@example.com',
      });
      await db.collection('users').doc('legacy-random-id').set({
        'role': 'teacher',
        'name': 'Legacy Profile',
        'email': 'admin@example.com',
      });

      final profile = await loadUser();

      expect(profile, isNotNull);
      expect(profile!['name'], 'UID-backed Admin');
      expect(role, 'admin');
      expect(isAdmin, isTrue);
    },
  );

  test('does not silently authorize an email-matched legacy profile', () async {
    await db.collection('users').doc('legacy-random-id').set({
      'role': 'admin',
      'name': 'Legacy Profile',
      'email': 'admin@example.com',
    });

    final profile = await loadUser();

    expect(profile, isNull);
  });
}
