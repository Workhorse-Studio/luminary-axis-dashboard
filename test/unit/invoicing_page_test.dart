import 'package:axis_dashboard/main.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('invoice mail tracking', () {
    test('persists Pending Payment after successful delivery', () async {
      final database = FakeFirebaseFirestore();
      final invoice = database.collection('invoices').doc('INV-STATUS');
      await invoice.set(<String, Object?>{
        'invoiceStatus': InvoiceStatus.pendingBilling.name,
      });

      await markInvoicePendingPayment(invoice);

      expect(
        (await invoice.get()).data()!['invoiceStatus'],
        InvoiceStatus.pendingPayment.name,
      );
    });

    test('issue repository records, orders, and resolves issues', () async {
      final database = FakeFirebaseFirestore();
      final repository = InvoiceMailIssueRepository(database);
      final older = InvoiceMailIssue(
        invoiceId: 'INV-OLD',
        recipientName: 'Older Student',
        recipientEmail: 'older@example.com',
        side: InvoiceMailIssueSide.client,
        stage: 'preparing',
        message: 'Old failure',
        occurredAt: DateTime.utc(2026, 8, 5),
      );
      final newer = InvoiceMailIssue(
        invoiceId: 'INV-NEW',
        recipientName: 'Newer Student',
        recipientEmail: 'newer@example.com',
        side: InvoiceMailIssueSide.server,
        stage: 'smtp_delivery',
        message: 'New failure',
        occurredAt: DateTime.utc(2026, 8, 6),
      );
      final olderReference = await repository.record(older);
      await repository.record(newer);

      final outstanding = await repository.loadOutstanding();
      expect(
        outstanding.map((issue) => issue.invoiceId),
        <String>['INV-NEW', 'INV-OLD'],
      );

      await repository.resolve(
        InvoiceMailIssue.fromJson(
          older.toJson(),
          documentId: olderReference.id,
        ),
        resolvedBy: 'admin@example.com',
        resolvedAt: DateTime.utc(2026, 8, 7),
      );

      expect(
        (await repository.loadOutstanding()).map((issue) => issue.invoiceId),
        <String>['INV-NEW'],
      );
      expect(
        (await olderReference.get()).data()!['resolvedBy'],
        'admin@example.com',
      );
    });

    test('tracks sent, attempted, progress, and itemized issues', () {
      final controller = InvoiceMailBatchController(<InvoiceMailExecutionState>[
        const InvoiceMailExecutionState(
          id: 'one',
          invoiceId: 'INV-1',
          recipientName: 'Alice',
          recipientEmail: 'alice@example.com',
        ),
        const InvoiceMailExecutionState(
          id: 'two',
          invoiceId: 'INV-2',
          recipientName: 'Bob',
          recipientEmail: 'bob@example.com',
        ),
      ]);
      final issue = InvoiceMailIssue(
        invoiceId: 'INV-2',
        recipientName: 'Bob',
        recipientEmail: 'bob@example.com',
        side: InvoiceMailIssueSide.server,
        stage: 'smtp_delivery',
        message: 'Mailbox rejected the recipient.',
        occurredAt: DateTime(2026, 8, 6),
        armCaseId: 'ARM-123',
      );

      controller.complete('one', delivered: true);
      controller.addIssue('two', issue);
      controller.complete('two', delivered: false);

      expect(controller.value.total, 2);
      expect(controller.value.attempted, 2);
      expect(controller.value.sent, 1);
      expect(controller.value.progress, 1);
      expect(controller.value.finished, isTrue);
      expect(controller.value.issues.single.message, contains('rejected'));
    });

    test('serializes user-readable issue details for history', () {
      final occurredAt = DateTime.utc(2026, 8, 6, 12, 30);
      final issue = InvoiceMailIssue(
        invoiceId: 'INV-3',
        recipientName: 'Carol',
        recipientEmail: 'carol@example.com',
        side: InvoiceMailIssueSide.client,
        stage: 'preparing',
        message: 'PDF rendering failed on page 2.',
        occurredAt: occurredAt,
        armCaseId: 'ARM-456',
      );

      final decoded = InvoiceMailIssue.fromJson(
        issue.toJson(),
        documentId: 'firestore-id',
      );

      expect(decoded.invoiceId, issue.invoiceId);
      expect(decoded.side, InvoiceMailIssueSide.client);
      expect(decoded.message, issue.message);
      expect(decoded.armCaseId, 'ARM-456');
      expect(decoded.documentId, 'firestore-id');
      expect(decoded.occurredAt.toUtc(), occurredAt);
    });

    test('bounded runner never exceeds configured concurrency', () async {
      var active = 0;
      var maximumObserved = 0;

      await runBoundedInvoiceMailTasks<int>(
        <int>[1, 2, 3, 4, 5],
        maximumConcurrent: 2,
        action: (_) async {
          active++;
          maximumObserved = maximumObserved < active ? active : maximumObserved;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          active--;
        },
      );

      expect(maximumObserved, 2);
      expect(active, 0);
    });

    testWidgets('issue table exposes resolution and ARM details', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final issue = InvoiceMailIssue(
        invoiceId: 'INV-7',
        recipientName: 'Dina',
        recipientEmail: 'dina@example.com',
        side: InvoiceMailIssueSide.server,
        stage: 'sent_folder_archive',
        message: 'Sent folder was unavailable.',
        occurredAt: DateTime(2026, 8, 6),
        armCaseId: 'ARM-789',
      );
      var resolved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvoiceMailIssuesTable(
              issues: <InvoiceMailIssue>[issue],
              onResolve: (_) async => resolved = true,
            ),
          ),
        ),
      );

      expect(find.text('Resolve'), findsNWidgets(2));
      expect(find.text('INV-7'), findsOneWidget);
      expect(find.text('dina@example.com'), findsOneWidget);
      expect(find.text('Server'), findsOneWidget);
      expect(find.text('ARM-789'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Resolve'));
      await tester.pump();
      expect(resolved, isTrue);
    });

    testWidgets('progress content updates live and exposes batch details', (
      tester,
    ) async {
      final controller = InvoiceMailBatchController(<InvoiceMailExecutionState>[
        const InvoiceMailExecutionState(
          id: 'one',
          invoiceId: 'INV-1',
          recipientName: 'Alice',
          recipientEmail: 'alice@example.com',
        ),
        const InvoiceMailExecutionState(
          id: 'two',
          invoiceId: 'INV-2',
          recipientName: 'Bob',
          recipientEmail: 'bob@example.com',
        ),
      ]);
      var infoTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvoiceMailProgressContent(
              controller: controller,
              onInfo: () => infoTaps++,
            ),
          ),
        ),
      );

      expect(find.text('Sent 0/2 invoices'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );

      controller.complete('one', delivered: true);
      await tester.pump();
      expect(find.text('Sent 1/2 invoices'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.5,
      );

      await tester.tap(find.byTooltip('Invoice mailing details'));
      expect(infoTaps, 1);
    });
  });

  group('createManualStudentInvoice', () {
    test('builds a transient invoice from only the supplied entries', () {
      final generatedAt = DateTime(2026, 7, 24, 10, 30);
      final student = StudentData(
        role: 'student',
        name: 'Alice Tan',
        email: 'alice@example.com',
        invoiceIds: const [],
        studentContactNo: '12345678',
        parentContactNo: '87654321',
        parentName: 'Parent Tan',
        withdrawn: const {},
        address: '1 Test Street',
        postalCode: '123456',
        school: 'Test School',
        subjectCombi: 'Math',
      );
      final entries = <InvoiceEntry>[
        (desc: 'Custom workshop', qty: 2, rate: 75, amt: 150),
        (desc: 'Materials', qty: 1, rate: 20, amt: 20),
      ];

      final invoice = createManualStudentInvoice(
        student: student,
        entries: entries,
        generatedAt: generatedAt,
      );

      expect(invoice.entries, same(entries));
      expect(invoice.amtPayable, 170);
      expect(invoice.studentName, 'Alice Tan');
      expect(invoice.parentName, 'Parent Tan');
      expect(invoice.invoiceDateFormatted, '24-07-2026');
      expect(invoice.dueDateFormatted, '31-07-2026');
      expect(invoice.invoiceId, 'MANUAL-${generatedAt.millisecondsSinceEpoch}');
    });
  });

  group('invoiceNameMatchesSearch', () {
    test('matches case-insensitive name fragments', () {
      expect(invoiceNameMatchesSearch('Alice Tan', 'ALIce'), isTrue);
      expect(invoiceNameMatchesSearch('Alice Tan', 'ice t'), isTrue);
    });

    test('matches multiple search terms regardless of extra whitespace', () {
      expect(
        invoiceNameMatchesSearch('Alice Mei Tan', '  alice   tan '),
        isTrue,
      );
      expect(invoiceNameMatchesSearch('Alice Mei Tan', 'alice lim'), isFalse);
    });

    test('matches close misspellings without accepting unrelated names', () {
      expect(invoiceNameMatchesSearch('Jonathan Lim', 'Jonathn'), isTrue);
      expect(invoiceNameMatchesSearch('Jonathan Lim', 'Jonatan'), isTrue);
      expect(invoiceNameMatchesSearch('Jonathan Lim', 'Michael'), isFalse);
      expect(invoiceNameMatchesSearch('Alice Tan', 'z'), isFalse);
    });

    test('empty searches include every name', () {
      expect(invoiceNameMatchesSearch('Alice Tan', '   '), isTrue);
    });
  });

  group('InvoicingPageState teacher month selection', () {
    test('defaults selected teacher month to current month', () {
      final now = DateTime.now();
      final state = InvoicingPageState();

      expect(state.selectedTeacherMonthId, '${now.month}-${now.year}');
    });

    test('generateMonthIds for current year only includes elapsed months', () {
      final now = DateTime.now();
      final state = InvoicingPageState()..year = now.year;

      final monthIds = state.generateMonthIds();

      expect(monthIds.length, now.month);
      expect(monthIds.first, '1-${now.year}');
      expect(monthIds.last, '${now.month}-${now.year}');
    });

    test('generateMonthIds for past year includes all 12 months', () {
      final now = DateTime.now();
      final state = InvoicingPageState()..year = now.year - 1;

      final monthIds = state.generateMonthIds();

      expect(monthIds.length, 12);
      expect(monthIds.first, '1-${now.year - 1}');
      expect(monthIds.last, '12-${now.year - 1}');
    });

    test('selectedTeacherMonthIdForYear keeps selected month when valid', () {
      final now = DateTime.now();
      final state = InvoicingPageState()
        ..year = now.year - 1
        ..selectedTeacherMonthId = '3-${now.year - 1}';

      expect(state.selectedTeacherMonthIdForYear(), '3-${now.year - 1}');
    });

    test('selectedTeacherMonthIdForYear falls back to current month', () {
      final now = DateTime.now();
      final state = InvoicingPageState()
        ..year = now.year
        ..selectedTeacherMonthId = '12-${now.year - 1}';

      expect(state.selectedTeacherMonthIdForYear(), '${now.month}-${now.year}');
    });

    test(
      'syncSelectedTeacherMonthIdForYear aligns selection to selected year',
      () {
        final now = DateTime.now();
        final state = InvoicingPageState()
          ..year = now.year - 1
          ..selectedTeacherMonthId = '${now.month}-${now.year}';

        state.syncSelectedTeacherMonthIdForYear();

        expect(state.selectedTeacherMonthId, '12-${now.year - 1}');
      },
    );

    test('formatMonthIdLabel formats month labels consistently', () {
      final state = InvoicingPageState();

      expect(state.formatMonthIdLabel('5-2026'), 'May 2026');
      expect(state.formatMonthIdLabel('11-2025'), 'November 2025');
    });
  });
}
