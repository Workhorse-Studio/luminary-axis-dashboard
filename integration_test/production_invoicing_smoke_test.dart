import 'package:axis_dashboard/main.dart';
import 'package:axis_dashboard/options.dart';
import 'package:arm_tooling/arm_tooling.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _runProductionSmoke = bool.fromEnvironment('RUN_PRODUCTION_SMOKE');
const _adminEmail = String.fromEnvironment('PROD_SMOKE_ADMIN_EMAIL');
const _adminPassword = String.fromEnvironment('PROD_SMOKE_ADMIN_PASSWORD');
const _recipient = String.fromEnvironment('PROD_SMOKE_RECIPIENT');
late IntegrationTestWidgetsFlutterBinding _binding;

void main() {
  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  _reportStage('binding_initialized');

  testWidgets(
    'production manual invoice creates disposable data, sends, and leaves no invoice record',
    (tester) async {
      expect(
        kReleaseMode,
        isTrue,
        reason: 'Production smoke tests must run with --release.',
      );
      expect(_recipient, isNotEmpty);

      await Firebase.initializeApp(options: options);
      _reportStage('firebase_initialized');
      if (_adminEmail.isNotEmpty && _adminPassword.isNotEmpty) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _adminEmail,
          password: _adminPassword,
        );
      }
      _reportStage('authentication_ready');
      role = 'admin';
      isAdmin = true;
      initializeArmClient();
      _reportStage('arm_initialized');

      final db = FirebaseFirestore.instance;
      final runId = DateTime.now().microsecondsSinceEpoch.toString();
      final studentReference = db
          .collection('users')
          .doc('__e2e_manual_invoice_$runId');
      final testStudent = StudentData(
        role: 'student',
        name: 'E2E Manual Invoice $runId',
        email: _recipient,
        invoiceIds: const [],
        studentContactNo: '80000000',
        parentContactNo: '90000000',
        parentName: 'E2E Parent',
        withdrawn: const {},
        address: '1 Integration Test Street',
        postalCode: '123456',
        school: 'E2E School',
        subjectCombi: 'Integration Testing',
      );
      StudentInvoiceData? sentInvoice;

      try {
        expect((await studentReference.get()).exists, isFalse);
        _reportStage('unique_id_verified');
        await studentReference.set(testStudent.toJson());
        _reportStage('student_created');
        final createdStudentDocument = await studentReference.get();
        expect(createdStudentDocument.exists, isTrue);
        final createdStudent = StudentData.fromJson(
          createdStudentDocument.data()!,
        );
        expect(createdStudent.name, testStudent.name);
        expect(createdStudent.email, _recipient);
        _reportStage('student_read_verified');

        _setDesktopViewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => ArmCaptureBoundary(
              controller: armCaptureBoundaryController,
              child: child ?? const SizedBox.shrink(),
            ),
            home: _ProductionManualInvoiceHarness(
              student: createdStudent,
              recipient: _recipient,
              onInvoice: (invoice) => sentInvoice = invoice,
            ),
          ),
        );
        _reportStage('harness_rendered');

        await tester.tap(find.byKey(const ValueKey('production-open-draft')));
        await tester.pumpAndSettle();
        _reportStage('dialog_opened');
        await _selectStudent(tester, createdStudent);
        _reportStage('student_selected');
        await _enterText(
          tester,
          find.byKey(
            const ValueKey('manual-invoice-entry-0-description'),
          ),
          'Production smoke test',
        );
        await _enterText(
          tester,
          find.byKey(const ValueKey('manual-invoice-entry-0-quantity')),
          '2',
        );
        await _enterText(
          tester,
          find.byKey(const ValueKey('manual-invoice-entry-0-amount')),
          '2.00',
        );
        _reportValue(
          'descriptionInput',
          _fieldText(
            tester,
            const ValueKey('manual-invoice-entry-0-description'),
          ),
        );
        _reportValue(
          'quantityInput',
          _fieldText(
            tester,
            const ValueKey('manual-invoice-entry-0-quantity'),
          ),
        );
        _reportValue(
          'amountInput',
          _fieldText(
            tester,
            const ValueKey('manual-invoice-entry-0-amount'),
          ),
        );
        await tester.tap(
          find.byKey(const ValueKey('manual-invoice-preview')),
        );
        await tester.pumpAndSettle();
        _reportStage('preview_rendered');

        final invoiceWidgetMatches = find
            .byType(StudentInvoiceWidget)
            .evaluate()
            .length;
        _reportValue('invoiceWidgetMatches', invoiceWidgetMatches);
        _reportValue(
          'entryNameErrors',
          find.text('Enter an entry name').evaluate().length,
        );
        _reportValue(
          'quantityErrors',
          find.text('Enter a valid quantity').evaluate().length,
        );
        _reportValue(
          'amountErrors',
          find.text('Enter a valid amount').evaluate().length,
        );
        expect(invoiceWidgetMatches, greaterThan(0));

        final descriptionMatches = find
            .text('Production smoke test')
            .evaluate()
            .length;
        _reportValue('previewDescriptionMatches', descriptionMatches);
        expect(descriptionMatches, greaterThan(0));
        _reportStage('preview_description_verified');
        final totalMatches = find.text('SGD 2.00').evaluate().length;
        _reportValue('previewTotalMatches', totalMatches);
        expect(totalMatches, greaterThan(0));
        _reportStage('preview_total_verified');
        final sendButton = find.byKey(const ValueKey('manual-invoice-send'));
        await tester.ensureVisible(sendButton);
        await tester.pumpAndSettle();
        await tester.tap(sendButton);
        _reportStage('send_started');
        final dialogClosed = await _pumpUntilAbsent(
          tester,
          find.byType(ManualInvoiceDialog),
          attempts: 300,
        );
        _reportValue('dialogClosedAfterSend', dialogClosed);
        _reportValue('invoiceCapturedBySend', sentInvoice != null);
        _reportValue(
          'snackbarMessages',
          tester
              .widgetList<Text>(
                find.descendant(
                  of: find.byType(SnackBar),
                  matching: find.byType(Text),
                ),
              )
              .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
              .where((text) => text.isNotEmpty)
              .toList(),
        );
        expect(dialogClosed, isTrue);
        _reportStage('send_completed');

        expect(sentInvoice, isNotNull);
        expect(sentInvoice!.entries, hasLength(1));
        expect(sentInvoice!.entries.single.qty, 2);
        expect(sentInvoice!.entries.single.rate, 1);
        expect(sentInvoice!.amtPayable, 2);

        final invoiceDocument = await db
            .collection('global')
            .doc('archives')
            .collection('invoices')
            .doc(sentInvoice!.invoiceId)
            .get();
        expect(
          invoiceDocument.exists,
          isFalse,
          reason: 'Manual invoices must never be stored in Firestore.',
        );
        _reportStage('non_persistence_verified');
      } finally {
        _reportCleanup('started');
        final invoice = sentInvoice;
        if (invoice != null) {
          final unexpectedInvoiceReference = db
              .collection('global')
              .doc('archives')
              .collection('invoices')
              .doc(invoice.invoiceId);
          if ((await unexpectedInvoiceReference.get()).exists) {
            await unexpectedInvoiceReference.delete();
          }
        }
        if ((await studentReference.get()).exists) {
          await studentReference.delete();
        }
        expect(
          (await studentReference.get()).exists,
          isFalse,
          reason: 'Disposable production student was not cleaned up.',
        );
        _reportCleanup('student_deleted');
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }
        _reportCleanup('complete');
      }
    },
    skip: !_runProductionSmoke,
  );
}

void _reportStage(String stage) {
  _binding.reportData = <String, dynamic>{
    ...?_binding.reportData,
    'lastStage': stage,
  };
}

void _reportCleanup(String stage) {
  _binding.reportData = <String, dynamic>{
    ...?_binding.reportData,
    'cleanupStage': stage,
  };
}

void _reportValue(String key, Object value) {
  _binding.reportData = <String, dynamic>{
    ...?_binding.reportData,
    key: value,
  };
}

class _ProductionManualInvoiceHarness extends InvoicingPage {
  const _ProductionManualInvoiceHarness({
    required this.student,
    required this.recipient,
    required this.onInvoice,
  });

  final StudentData student;
  final String recipient;
  final ValueChanged<StudentInvoiceData> onInvoice;

  @override
  State<StatefulWidget> createState() => _ProductionManualInvoiceHarnessState();
}

class _ProductionManualInvoiceHarnessState extends InvoicingPageState {
  _ProductionManualInvoiceHarness get harness =>
      widget as _ProductionManualInvoiceHarness;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: AxisButton.text(
            key: const ValueKey('production-open-draft'),
            label: 'Open production draft',
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (_) => ManualInvoiceDialog(
                students: [harness.student],
                onSend: (_, invoice) async {
                  harness.onInvoice(invoice);
                  return sendInvoiceEmail(
                    harness.recipient,
                    StudentInvoiceWidget(
                      showFonts: false,
                      studentInvoiceData: invoice,
                      total: invoice.amtPayable,
                    ),
                    context,
                    timestampLabel:
                        'Production E2E Manual Invoice ${invoice.invoiceId}',
                    onProgress: (stage) => _reportValue('sendProgress', stage),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  await tester.pumpAndSettle();
}

Future<bool> _pumpUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  required int attempts,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return true;
  }
  return false;
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
