import 'package:axis_dashboard/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live batch progress opens itemized delivery failures', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = InvoiceMailBatchController(<InvoiceMailExecutionState>[
      const InvoiceMailExecutionState(
        id: 'success',
        invoiceId: 'INV-SUCCESS',
        recipientName: 'Successful Student',
        recipientEmail: 'success@example.com',
      ),
      const InvoiceMailExecutionState(
        id: 'failure',
        invoiceId: 'INV-FAILURE',
        recipientName: 'Affected Student',
        recipientEmail: 'affected@example.com',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('start-mail-batch'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(days: 365),
                      content: InvoiceMailProgressContent(
                        controller: controller,
                        onInfo: () => showDialog<void>(
                          context: context,
                          builder: (dialogContext) => InvoiceMailIssuesDialog(
                            issues: controller.value.issues,
                            onClose: () => Navigator.of(dialogContext).pop(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('start-mail-batch')));
    await tester.pump();
    expect(find.text('Sent 0/2 invoices'), findsOneWidget);

    controller.complete('success', delivered: true);
    controller.addIssue(
      'failure',
      InvoiceMailIssue(
        invoiceId: 'INV-FAILURE',
        recipientName: 'Affected Student',
        recipientEmail: 'affected@example.com',
        side: InvoiceMailIssueSide.server,
        stage: 'smtp_delivery',
        message: 'Recipient mailbox rejected the message.',
        occurredAt: DateTime.utc(2026, 8, 6),
        armCaseId: 'ARM-PROD-TEST',
      ),
    );
    controller.complete('failure', delivered: false);
    await tester.pump();

    expect(find.text('Sent 1/2 invoices • 1 issues'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value,
      1,
    );

    await tester.tap(find.byTooltip('Invoice mailing details'));
    await tester.pumpAndSettle();
    expect(find.text('INV-FAILURE'), findsOneWidget);
    expect(find.text('Affected Student'), findsOneWidget);
    expect(find.text('affected@example.com'), findsOneWidget);
    expect(find.text('Server'), findsOneWidget);
    expect(find.text('ARM-PROD-TEST'), findsOneWidget);
  });
}
