// Browser workflow shared by the integration-test entry point.
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

  setUp(() async {
    db = FakeFirebaseFirestore();
    overrideFirestoreForTesting(db);
    overrideAuthForTesting(
      MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'invoicing-admin',
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
    await _seedInvoicingData(db);
  });

  tearDown(() {
    resetFirestoreOverride();
    resetAuthOverride();
  });

  group('invoicing page workflow', () {
    testWidgets(
      'paginates, searches fuzzily, scopes actions, and opens student details',
      (tester) async {
        _setDesktopViewport(tester);

        await tester.pumpWidget(
          const MaterialApp(home: InvoicingPage()),
        );
        await _pumpUntilFound(
          tester,
          find.byKey(const ValueKey('manual-invoice-open')),
        );
        await _pumpUntilFound(tester, find.text('E2E Client 00'));
        _expectNoRenderingErrors(tester, 'Loaded invoicing page');

        expect(find.text('E2E Client 00'), findsOneWidget);
        expect(find.text('E2E Client 11'), findsNothing);
        expect(find.byTooltip('Next page'), findsOneWidget);

        await tester.tap(find.byTooltip('Next page'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('E2E Client 11'), findsOneWidget);

        final search = find.byKey(const ValueKey('invoice-name-search'));
        await tester.enterText(search, 'Clent 11');
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('E2E Client 11'), findsOneWidget);
        expect(find.text('E2E Client 10'), findsNothing);

        await tester.enterText(search, 'no-such-student');
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('No names match your search.'), findsOneWidget);

        await tester.enterText(search, 'Client 00');
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.text('E2E Client 00'));
        await _pumpUntilFound(tester, find.text('Student Information'));
        expect(
          find.textContaining(
            'e2e-client-00@example.com',
            findRichText: true,
          ),
          findsOneWidget,
        );
        await _pumpUntilFound(
          tester,
          find.text('Not registered for any classes.'),
        );
        expect(find.text('Not registered for any classes.'), findsOneWidget);
        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
        expect(find.text('Student Information'), findsNothing);

        await tester.tap(find.text('Teachers'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          find.byKey(const ValueKey('manual-invoice-open')),
          findsNothing,
        );
        _expectNoRenderingErrors(tester, 'Teacher tab');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'manual draft validates, adds and removes entries, previews, retries send, and discards',
      (tester) async {
        _setDesktopViewport(tester);
        final student = _student(99);
        StudentInvoiceData? sentInvoice;
        var sendAttempts = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: AxisButton.text(
                    key: const ValueKey('open-manual-dialog-test'),
                    width: 180,
                    height: 56,
                    label: 'Open draft',
                    onPressed: () => showDialog<void>(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => ManualInvoiceDialog(
                        students: [student, _student(98)],
                        onSend: (_, invoice) async {
                          sentInvoice = invoice;
                          sendAttempts++;
                          return sendAttempts > 1;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('open-manual-dialog-test')),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(TextFormField), findsNothing);

        await _selectStudent(tester, student);
        expect(find.byType(TextFormField), findsNWidgets(3));

        await tester.tap(
          find.byKey(const ValueKey('manual-invoice-preview')),
        );
        await tester.pump();
        expect(find.text('Enter an entry name'), findsOneWidget);
        expect(find.text('Enter a valid amount'), findsOneWidget);

        await _enterText(
          tester,
          find.byKey(
            const ValueKey('manual-invoice-entry-0-description'),
          ),
          'Custom workshop',
        );
        await _enterText(
          tester,
          find.byKey(const ValueKey('manual-invoice-entry-0-quantity')),
          '0',
        );
        await _enterText(
          tester,
          find.byKey(const ValueKey('manual-invoice-entry-0-amount')),
          'not-a-number',
        );
        await tester.tap(
          find.byKey(const ValueKey('manual-invoice-preview')),
        );
        await tester.pump();
        expect(find.text('Enter a valid quantity'), findsOneWidget);
        expect(find.text('Enter a valid amount'), findsOneWidget);

        await _enterText(
          tester,
          find.byKey(const ValueKey('manual-invoice-entry-0-quantity')),
          '2',
        );
        await _enterText(
          tester,
          find.byKey(const ValueKey('manual-invoice-entry-0-amount')),
          '150.00',
        );
        await tester.tap(
          find.byKey(const ValueKey('manual-invoice-add-entry')),
        );
        await tester.pump();
        await _enterText(
          tester,
          find.byKey(
            const ValueKey('manual-invoice-entry-1-description'),
          ),
          'Materials',
        );
        await _enterText(
          tester,
          find.byKey(const ValueKey('manual-invoice-entry-1-quantity')),
          '1',
        );
        await _enterText(
          tester,
          find.byKey(const ValueKey('manual-invoice-entry-1-amount')),
          '20',
        );

        await tester.tap(
          find.byKey(const ValueKey('manual-invoice-add-entry')),
        );
        await tester.pump();
        expect(find.byType(TextFormField), findsNWidgets(9));
        await tester.tap(
          find.byKey(const ValueKey('manual-invoice-entry-2-remove')),
        );
        await tester.pump();
        expect(find.byType(TextFormField), findsNWidgets(6));

        await tester.tap(
          find.byKey(const ValueKey('manual-invoice-preview')),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('TAX INVOICE'), findsOneWidget);
        expect(find.text('Custom workshop'), findsOneWidget);
        expect(find.text('Materials'), findsOneWidget);
        expect(find.text('SGD 170.00'), findsOneWidget);

        final editDraftButton = find.byKey(
          const ValueKey('manual-invoice-edit-draft'),
        );
        await tester.ensureVisible(editDraftButton);
        await tester.pumpAndSettle();
        await tester.tap(editDraftButton);
        await tester.pump();
        expect(
          _fieldText(
            tester,
            const ValueKey('manual-invoice-entry-0-description'),
          ),
          'Custom workshop',
        );
        await tester.tap(
          find.byKey(const ValueKey('manual-invoice-preview')),
        );
        await tester.pump(const Duration(milliseconds: 200));

        final sendButton = find.byKey(const ValueKey('manual-invoice-send'));
        await tester.ensureVisible(sendButton);
        await tester.pumpAndSettle();
        await tester.tap(sendButton);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(ManualInvoiceDialog), findsOneWidget);
        expect(sendAttempts, 1);

        await tester.tap(sendButton);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(ManualInvoiceDialog), findsNothing);
        expect(sendAttempts, 2);
        expect(sentInvoice!.entries, hasLength(2));
        expect(sentInvoice!.entries.first.amt, 150);
        expect(sentInvoice!.entries.first.rate, 75);
        expect(sentInvoice!.amtPayable, 170);

        await tester.tap(
          find.byKey(const ValueKey('open-manual-dialog-test')),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await _selectStudent(tester, student);
        await tester.tapAt(const Offset(8, 8));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(ManualInvoiceDialog), findsNothing);
        expect(sendAttempts, 2, reason: 'Discarding must not invoke send');
        _expectNoRenderingErrors(tester, 'Manual invoice workflow');
      },
      // Flutter's Chrome unit-test text handler cannot mount DropdownMenu.
      // The canonical flutter-drive wrapper runs this workflow instead.
      skip: !useIntegrationBinding,
    );
  });
}

Future<void> _seedInvoicingData(FakeFirebaseFirestore db) async {
  const term = TermData(
    termName: 'E2E Term',
    termStartDate: 1735689600000,
    termEndDate: 1798761599000,
  );
  await db
      .collection('global')
      .doc('state')
      .set(
        const GlobalState(terms: [term], currentTermNum: 0).toJson(),
      );
  await db
      .collection('global')
      .doc('state')
      .collection('allocations')
      .doc(term.termName)
      .set({});
  for (var index = 0; index < 12; index++) {
    await db
        .collection('users')
        .doc('e2e-client-${index.toString().padLeft(2, '0')}')
        .set(_student(index).toJson());
  }
}

StudentData _student(int index) {
  final padded = index.toString().padLeft(2, '0');
  return StudentData(
    role: 'student',
    name: 'E2E Client $padded',
    email: 'e2e-client-$padded@example.com',
    invoiceIds: const [null],
    studentContactNo: '80000000',
    parentContactNo: '90000000',
    parentName: 'E2E Parent $padded',
    withdrawn: const {},
    address: '$index Test Street',
    postalCode: '123456',
    school: 'E2E School',
    subjectCombi: 'Mathematics',
  );
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for an expected widget.');
}

Future<void> _selectStudent(
  WidgetTester tester,
  StudentData student,
) async {
  final dropdown = find.byKey(
    const ValueKey('manual-invoice-student-dropdown'),
  );
  await tester.tap(dropdown);
  await tester.pump();
  await tester.enterText(
    find.descendant(of: dropdown, matching: find.byType(TextField)),
    student.name,
  );
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text(student.name).last);
  await tester.pump(const Duration(milliseconds: 200));
}

String _fieldText(WidgetTester tester, Key key) =>
    tester.widget<TextFormField>(find.byKey(key)).controller!.text;

Future<void> _enterText(
  WidgetTester tester,
  Finder field,
  String value,
) async {
  // Synthetic keyboard input is dropped by Flutter's release web driver.
  tester.widget<TextFormField>(field).controller!.text = value;
  await tester.pump();
}

void _expectNoRenderingErrors(WidgetTester tester, String stage) {
  final error = tester.takeException();
  if (error != null) {
    fail('$stage rendered with an exception: $error');
  }
}
