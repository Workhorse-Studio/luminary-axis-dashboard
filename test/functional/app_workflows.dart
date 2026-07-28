import 'package:axis_dashboard/main.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main({bool useIntegrationBinding = true}) {
  if (useIntegrationBinding) {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  } else {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  late FakeFirebaseFirestore db;
  var armInitialized = false;

  setUp(() {
    db = FakeFirebaseFirestore();
    overrideFirestoreForTesting(db);
    overrideAuthForTesting(
      MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'admin-1',
          email: 'admin@example.com',
          customClaim: const {'role': 'admin'},
        ),
        signedIn: true,
      ),
    );
    role = 'admin';
    isAdmin = true;
    if (!armInitialized) {
      initializeArmClient();
      armInitialized = true;
    }
    studentAttendanceStore.markStale();
  });

  tearDown(() {
    resetFirestoreOverride();
    resetAuthOverride();
  });

  group('student lifecycle workflow', () {
    testWidgets(
      'onboarding rejects incomplete input then persists every field correctly',
      (tester) async {
        void expectNoRenderingErrors(String stage) {
          final error = tester.takeException();
          if (error != null) {
            fail('$stage rendered with an exception: $error');
          }
        }

        tester.view.physicalSize = const Size(1440, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await db.collection('templates').doc('math-hl').set({
          'className': 'HL Mathematics',
        });
        await db.collection('users').doc('teacher-1').set({
          ..._teacherJson,
          'name': 'Ms Lim',
        });

        await tester.pumpWidget(
          const MaterialApp(home: OnboardingPage()),
        );
        await tester.pumpAndSettle();
        expectNoRenderingErrors('Initial onboarding form');

        await tester.ensureVisible(find.text('Submit'));
        await tester.tap(find.text('Submit'));
        await tester.pump();
        expectNoRenderingErrors('Validation feedback');
        expect(
          find.text(
            'Ensure no fields are empty, and all questions are answered.',
          ),
          findsOneWidget,
        );
        expect(
          (await db
                  .collection('global')
                  .doc('state')
                  .collection('pendingOnboarding')
                  .get())
              .docs,
          isEmpty,
        );

        final fields = find.byType(TextField);
        final values = <String>[
          'Alicia Tan',
          '81234567',
          'billing@example.com',
          'Axis Secondary',
          'Grace Tan',
          '98765432',
          '1 Test Street',
          '123456',
          'Physics, Math',
          'FRIEND-42',
        ];
        expect(fields, findsNWidgets(values.length));
        for (var i = 0; i < values.length; i++) {
          await tester.enterText(fields.at(i), values[i]);
        }
        // Model the time a person needs to complete the form and let the
        // validation snackbar clear before they press Submit again.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Checkbox).first);
        await tester.pump();
        expectNoRenderingErrors('Class selection');
        final onboardingState = tester.state<OnboardingPageState>(
          find.byType(OnboardingPage),
        );
        expect(onboardingState.selections, hasLength(1));
        await tester.ensureVisible(find.text('Submit'));
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();
        expectNoRenderingErrors('Successful submission feedback');
        final pending = await db
            .collection('global')
            .doc('state')
            .collection('pendingOnboarding')
            .get();
        expect(pending.docs, hasLength(1));
        expect(
          pending.docs.single.data(),
          containsPair('studentName', 'Alicia Tan'),
        );
        expect(
          pending.docs.single.data(),
          containsPair('parentName', 'Grace Tan'),
        );
        expect(
          pending.docs.single.data(),
          containsPair('parentContactNo', '98765432'),
        );
        expect(
          pending.docs.single.data(),
          containsPair('classes', ['math-hl']),
        );
        expect(
          pending.docs.single.data(),
          containsPair('referralCode', 'FRIEND-42'),
        );
      },
    );

    test(
      'approved onboarding is idempotent for the same person and email',
      () async {
        await _seedGlobalState(db);
        const form = OnboardingStudentData(
          studentContactNo: '81234567',
          studentName: 'Alicia Tan',
          parentContactNo: '98765432',
          parentName: 'Grace Tan',
          email: 'billing@example.com',
          address: '1 Test Street',
          postalCode: '123456',
          school: 'Axis Secondary',
          subjectCombi: 'Physics, Math',
          referralCode: 'FRIEND-42',
          classes: ['math-hl'],
        );

        final firstId = await onboardStudent(form);
        final secondId = await onboardStudent(form);

        expect(secondId, firstId);
        final students = await db
            .collection('users')
            .where('role', isEqualTo: 'student')
            .get();
        expect(students.docs, hasLength(1));
        final student = StudentData.fromJson(students.docs.single.data());
        expect(student.invoiceIds, [null, null]);
        expect(student.referralCode, 'FRIEND-42');
      },
    );

    test(
      'registration updates roster and current allocation, withdrawal preserves history',
      () async {
        await _seedGlobalState(db);
        await db.collection('users').doc('student-1').set(_studentJson());
        await db.collection('classes').doc('class-1').set(_classJson());

        await registerStudentForClass(
          studentId: 'student-1',
          classId: 'class-1',
          initialSessionsCount: 7,
        );

        final registeredStudent =
            (await db.collection('users').doc('student-1').get()).data()!;
        final registeredClass =
            (await db.collection('classes').doc('class-1').get()).data()!;
        final allocation =
            (await db
                    .collection('global')
                    .doc('state')
                    .collection('allocations')
                    .doc('Term 2')
                    .get())
                .data()!;
        expect(
          registeredStudent['initialSessionCount'],
          containsPair('class-1', 7),
        );
        expect(
          registeredStudent['withdrawn'],
          containsPair('class-1', false),
        );
        expect(registeredClass['students'], ['student-1']);
        expect(allocation['class-1'], {'student-1': 7});

        await withdrawStudentFromClass(
          studentId: 'student-1',
          classId: 'class-1',
        );
        final withdrawnStudent =
            (await db.collection('users').doc('student-1').get()).data()!;
        expect(
          withdrawnStudent['withdrawn'],
          containsPair('class-1', true),
        );
        expect(
          (await db.collection('classes').doc('class-1').get())
              .data()!['students'],
          ['student-1'],
          reason: 'historical reports require the roster entry to remain',
        );
      },
    );
  });

  group('attendance to invoice workflow', () {
    test(
      'multiple same-day sessions produce one invoice and reruns are idempotent',
      () async {
        await _seedGlobalState(db, oneTerm: true);
        await db.collection('users').doc('student-1').set(_studentJson());
        await db
            .collection('classes')
            .doc('class-1')
            .set(
              _classJson(
                students: ['student-1'],
                attendance: {
                  '14-5-2026__s001': {'student-1': 'presentPhysical'},
                  '14-5-2026__s002': {'student-1': 'presentOnline'},
                  '21-5-2026__s001': {'student-1': 'absent'},
                },
              ),
            );
        await db
            .collection('global')
            .doc('state')
            .collection('allocations')
            .doc('Term 1')
            .set({
              'class-1': {'student-1': 2},
            });

        final classes = GenericCache(
          (id) => db.collection('classes').doc(id).get(),
        );
        final students = GenericCache(
          (id) => db.collection('users').doc(id).get(),
        );
        await classes.initAll(collection: db.collection('classes'));
        await students.initAll(
          query: db.collection('users').where('role', isEqualTo: 'student'),
        );
        final state = GlobalState.fromJson(
          (await db.collection('global').doc('state').get()).data()!,
        );
        final store = StudentAttendanceStore();

        expect(
          await store.run(
            globalState: state,
            classesCache: classes,
            studentCache: students,
          ),
          1,
        );
        expect(store.sessionsPerTerm.single['student-1']!['class-1'], 2);
        expect(
          store.termReports.single['student-1']!['class-1'],
          ['14-5 S1', '14-5 S2', 'X'],
        );
        final invoice = store.invoicesData.single['student-1']!;
        expect(invoice.entries.single.qty, 2);
        expect(invoice.entries.single.amt, 190);
        expect(invoice.amtPayable, 190);

        expect(
          await store.run(
            globalState: state,
            classesCache: classes,
            studentCache: students,
          ),
          0,
          reason: 'unchanged attendance must not create a replacement invoice',
        );
        expect(
          (await db
                  .collection('global')
                  .doc('archives')
                  .collection('invoices')
                  .get())
              .docs,
          hasLength(1),
        );
      },
    );
  });

  group('destructive UI safeguards', () {
    testWidgets('confirmation cancel and continue return distinct decisions', (
      tester,
    ) async {
      Future<bool?> showConfirmation() => showDialog<bool>(
        context: tester.element(find.byType(Scaffold)),
        builder: (_) => const ConfirmationDialog(
          confirmationMsg: 'Delete this attendance session?',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand())),
      );
      var result = showConfirmation();
      await tester.pumpAndSettle();
      final confirmationBuildException = tester.takeException();
      expect(confirmationBuildException, isNull);
      expect(find.text('Delete this attendance session?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);

      result = showConfirmation();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(await result, isTrue);
    });
  });
}

Future<void> _seedGlobalState(
  FakeFirebaseFirestore db, {
  bool oneTerm = false,
}) async {
  final terms = [
    const TermData(
      termName: 'Term 1',
      termStartDate: 1735689600000,
      termEndDate: 1782863999000,
    ),
    if (!oneTerm)
      const TermData(
        termName: 'Term 2',
        termStartDate: 1782864000000,
        termEndDate: 1798761599000,
      ),
  ];
  await db
      .collection('global')
      .doc('state')
      .set(
        GlobalState(
          terms: terms,
          currentTermNum: terms.length - 1,
        ).toJson(),
      );
}

Map<String, Object?> _studentJson() => const StudentData(
  role: 'student',
  name: 'Alicia Tan',
  email: 'billing@example.com',
  invoiceIds: [null],
  studentContactNo: '81234567',
  parentContactNo: '98765432',
  parentName: 'Grace Tan',
  withdrawn: {},
  address: '1 Test Street',
  postalCode: '123456',
  school: 'Axis Secondary',
  subjectCombi: 'Physics, Math',
).toJson();

Map<String, Object?> _classJson({
  List<String> students = const [],
  Map<String, Map<String, String>> attendance = const {},
}) => {
  'name': 'HL Mathematics',
  'students': students,
  'templateReference': 'math-hl',
  'attendance': attendance,
};

const Map<String, Object?> _teacherJson = {
  'role': 'teacher',
  'name': 'Teacher',
  'email': 'teacher@example.com',
  'classes': <String>[],
  'invoiceIds': <String, String>{},
  'offeredClassTemplates': <String>[],
};
