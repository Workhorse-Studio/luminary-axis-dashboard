part of axis_dashboard;

enum InvoiceMailStage {
  queued,
  loading,
  preparing,
  transferring,
  updatingPaymentStatus,
  completed,
}

enum InvoiceMailIssueSide {
  client('Client'),
  server('Server');

  const InvoiceMailIssueSide(this.label);
  final String label;
}

class InvoiceMailIssue {
  const InvoiceMailIssue({
    required this.invoiceId,
    required this.recipientName,
    required this.recipientEmail,
    required this.side,
    required this.stage,
    required this.message,
    required this.occurredAt,
    this.armCaseId,
    this.documentId,
  });

  final String invoiceId;
  final String recipientName;
  final String recipientEmail;
  final InvoiceMailIssueSide side;
  final String stage;
  final String message;
  final DateTime occurredAt;
  final String? armCaseId;
  final String? documentId;

  JSON toJson() => <String, Object?>{
    'invoiceId': invoiceId,
    'recipientName': recipientName,
    'recipientEmail': recipientEmail,
    'side': side.name,
    'stage': stage,
    'message': message,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'armCaseId': armCaseId,
    'resolved': false,
  };

  factory InvoiceMailIssue.fromJson(
    JSON json, {
    String? documentId,
  }) => InvoiceMailIssue(
    invoiceId: (json['invoiceId'] as String?) ?? 'Unknown',
    recipientName: (json['recipientName'] as String?) ?? 'Unknown',
    recipientEmail: (json['recipientEmail'] as String?) ?? 'Unknown',
    side: (json['side'] as String?) == InvoiceMailIssueSide.server.name
        ? InvoiceMailIssueSide.server
        : InvoiceMailIssueSide.client,
    stage: (json['stage'] as String?) ?? 'unknown',
    message: (json['message'] as String?) ?? 'No error details were recorded.',
    occurredAt:
        DateTime.tryParse((json['occurredAt'] as String?) ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    armCaseId: json['armCaseId'] as String?,
    documentId: documentId,
  );
}

class InvoiceMailIssueRepository {
  InvoiceMailIssueRepository(this.database);

  final FirebaseFirestore database;

  CollectionReference<JSON> get _collection => database
      .collection('global')
      .doc('archives')
      .collection('invoiceMailIssues');

  Future<DocumentReference<JSON>> record(InvoiceMailIssue issue) =>
      _collection.add(issue.toJson());

  Future<List<InvoiceMailIssue>> loadOutstanding() async {
    final snapshot = await _collection.get();
    return <InvoiceMailIssue>[
      for (final document in snapshot.docs)
        if (document.data()['resolved'] != true)
          InvoiceMailIssue.fromJson(
            document.data(),
            documentId: document.id,
          ),
    ]..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
  }

  Future<void> resolve(
    InvoiceMailIssue issue, {
    required String? resolvedBy,
    DateTime? resolvedAt,
  }) async {
    final documentId = issue.documentId;
    if (documentId == null || documentId.isEmpty) {
      throw ArgumentError('A persisted issue document ID is required.');
    }
    await _collection.doc(documentId).update(<String, Object?>{
      'resolved': true,
      'resolvedAt': (resolvedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'resolvedBy': resolvedBy,
    });
  }
}

Future<void> markInvoicePendingPayment(DocumentReference<JSON> invoice) =>
    invoice.update(<String, Object?>{
      'invoiceStatus': InvoiceStatus.pendingPayment.name,
    });

class InvoiceMailExecutionState {
  const InvoiceMailExecutionState({
    required this.id,
    required this.invoiceId,
    required this.recipientName,
    required this.recipientEmail,
    this.stage = InvoiceMailStage.queued,
    this.delivered = false,
    this.finished = false,
    this.issues = const <InvoiceMailIssue>[],
  });

  final String id;
  final String invoiceId;
  final String recipientName;
  final String recipientEmail;
  final InvoiceMailStage stage;
  final bool delivered;
  final bool finished;
  final List<InvoiceMailIssue> issues;

  InvoiceMailExecutionState copyWith({
    String? recipientName,
    String? recipientEmail,
    InvoiceMailStage? stage,
    bool? delivered,
    bool? finished,
    List<InvoiceMailIssue>? issues,
  }) => InvoiceMailExecutionState(
    id: id,
    invoiceId: invoiceId,
    recipientName: recipientName ?? this.recipientName,
    recipientEmail: recipientEmail ?? this.recipientEmail,
    stage: stage ?? this.stage,
    delivered: delivered ?? this.delivered,
    finished: finished ?? this.finished,
    issues: issues ?? this.issues,
  );
}

class InvoiceMailBatchSnapshot {
  const InvoiceMailBatchSnapshot(this.executions);

  final List<InvoiceMailExecutionState> executions;

  int get total => executions.length;
  int get attempted => executions.where((entry) => entry.finished).length;
  int get sent => executions.where((entry) => entry.delivered).length;
  bool get finished => attempted == total;
  double get progress => total == 0 ? 1 : attempted / total;
  List<InvoiceMailIssue> get issues => <InvoiceMailIssue>[
    for (final execution in executions) ...execution.issues,
  ];
}

class InvoiceMailBatchController
    extends ValueNotifier<InvoiceMailBatchSnapshot> {
  InvoiceMailBatchController(Iterable<InvoiceMailExecutionState> executions)
    : super(InvoiceMailBatchSnapshot(executions.toList(growable: false)));

  void updateStage(String id, InvoiceMailStage stage) {
    _replace(id, (entry) => entry.copyWith(stage: stage));
  }

  void updateRecipient(
    String id, {
    required String name,
    required String email,
  }) {
    _replace(
      id,
      (entry) => entry.copyWith(recipientName: name, recipientEmail: email),
    );
  }

  void addIssue(String id, InvoiceMailIssue issue) {
    _replace(
      id,
      (entry) => entry.copyWith(
        issues: <InvoiceMailIssue>[
          ...entry.issues,
          issue,
        ],
      ),
    );
  }

  void complete(String id, {required bool delivered}) {
    _replace(
      id,
      (entry) => entry.copyWith(
        stage: InvoiceMailStage.completed,
        delivered: delivered,
        finished: true,
      ),
    );
  }

  void _replace(
    String id,
    InvoiceMailExecutionState Function(InvoiceMailExecutionState) transform,
  ) {
    value = InvoiceMailBatchSnapshot(<InvoiceMailExecutionState>[
      for (final entry in value.executions)
        if (entry.id == id) transform(entry) else entry,
    ]);
  }
}

Future<void> runBoundedInvoiceMailTasks<T>(
  List<T> tasks, {
  required int maximumConcurrent,
  required Future<void> Function(T task) action,
}) async {
  if (maximumConcurrent < 1) {
    throw ArgumentError.value(maximumConcurrent, 'maximumConcurrent');
  }
  var nextIndex = 0;
  Future<void> worker() async {
    while (nextIndex < tasks.length) {
      final task = tasks[nextIndex++];
      await action(task);
      await Future<void>.delayed(Duration.zero);
    }
  }

  await Future.wait(<Future<void>>[
    for (var i = 0; i < min(maximumConcurrent, tasks.length); i++) worker(),
  ]);
}

class InvoiceMailIssuesTable extends StatelessWidget {
  const InvoiceMailIssuesTable({
    required this.issues,
    this.onResolve,
    super.key,
  });

  final List<InvoiceMailIssue> issues;
  final Future<void> Function(InvoiceMailIssue issue)? onResolve;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.mark_email_read_outlined,
                size: 40,
                color: AxisColors.lilacPurple20.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                'No invoice mailing issues to show.',
                style: body2.copyWith(
                  color: AxisColors.white50.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return DataTable2(
      minWidth: onResolve == null ? 1050 : 1240,
      columnSpacing: 20,
      horizontalMargin: 20,
      headingRowHeight: 56,
      dataRowHeight: 76,
      dividerThickness: 0.2,
      headingTextStyle: body2.copyWith(
        color: AxisColors.white50.withValues(alpha: 0.8),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      dataTextStyle: body2.copyWith(
        color: AxisColors.white50.withValues(alpha: 0.65),
        fontSize: 14,
      ),
      headingRowColor: WidgetStatePropertyAll(
        AxisColors.blackPurple30.withValues(alpha: 0.7),
      ),
      border: TableBorder(
        verticalInside: BorderSide(
          color: AxisColors.blackPurple20.withValues(alpha: 0.35),
          width: 1,
        ),
        horizontalInside: BorderSide(
          color: AxisColors.blackPurple20.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      columns: <DataColumn2>[
        if (onResolve != null)
          const DataColumn2(fixedWidth: 160, label: Text('Resolve')),
        const DataColumn2(fixedWidth: 135, label: Text('Invoice')),
        const DataColumn2(size: ColumnSize.M, label: Text('Student / Payee')),
        const DataColumn2(size: ColumnSize.L, label: Text('Email')),
        const DataColumn2(fixedWidth: 90, label: Text('Side')),
        const DataColumn2(size: ColumnSize.L, label: Text('Error')),
        const DataColumn2(fixedWidth: 150, label: Text('ARM case ID')),
      ],
      rows: <DataRow>[
        for (final issue in issues)
          DataRow(
            cells: <DataCell>[
              if (onResolve != null)
                DataCell(
                  TextButton.icon(
                    key: ValueKey(
                      'resolve-invoice-mail-${issue.documentId ?? issue.invoiceId}',
                    ),
                    onPressed: () => onResolve!(issue),
                    style: TextButton.styleFrom(
                      foregroundColor: AxisColors.lilacPurple20,
                      backgroundColor: AxisColors.blackPurple30.withValues(
                        alpha: 0.35,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: AxisColors.blackPurple20.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'Resolve',
                      style: body2.copyWith(
                        color: AxisColors.lilacPurple20,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              DataCell(Text(issue.invoiceId)),
              DataCell(Text(issue.recipientName)),
              DataCell(Text(issue.recipientEmail)),
              DataCell(Text(issue.side.label)),
              DataCell(
                Tooltip(
                  message: '${issue.stage}: ${issue.message}',
                  child: Text(
                    issue.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(SelectableText(issue.armCaseId ?? '—')),
            ],
          ),
      ],
    );
  }
}

class InvoiceMailIssuesDialog extends StatelessWidget {
  const InvoiceMailIssuesDialog({
    required this.issues,
    required this.onClose,
    this.onResolve,
    super.key,
  });

  final List<InvoiceMailIssue> issues;
  final VoidCallback onClose;
  final Future<void> Function(InvoiceMailIssue issue)? onResolve;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final dialogWidth = min(1320.0, max(0.0, mediaSize.width - 48));
    final dialogHeight = min(720.0, max(0.0, mediaSize.height - 48));

    return Dialog(
      key: const ValueKey('invoice-mail-issues-dialog'),
      backgroundColor: AxisColors.blackPurple50,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AxisColors.blackPurple20),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 20, 20),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AxisColors.blackPurple30.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AxisColors.blackPurple20.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      color: AxisColors.lilacPurple20.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Invoice mailing issues', style: heading2),
                        const SizedBox(height: 4),
                        Text(
                          onResolve == null
                              ? 'Delivery issues recorded for this mailing run.'
                              : 'Review and resolve outstanding invoice delivery issues.',
                          style: body2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    key: const ValueKey('close-invoice-mail-issues-dialog'),
                    tooltip: 'Close',
                    onPressed: onClose,
                    style: IconButton.styleFrom(
                      foregroundColor: AxisColors.lilacPurple20,
                      backgroundColor: AxisColors.blackPurple30.withValues(
                        alpha: 0.35,
                      ),
                      hoverColor: AxisColors.lilacPurple20.withValues(
                        alpha: 0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AxisColors.blackPurple20.withValues(alpha: 0.5),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AxisColors.blackPurple30.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AxisColors.blackPurple20.withValues(alpha: 0.45),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: InvoiceMailIssuesTable(
                      issues: issues,
                      onResolve: onResolve,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceMailProgressContent extends StatelessWidget {
  const InvoiceMailProgressContent({
    required this.controller,
    required this.onInfo,
    super.key,
  });

  final InvoiceMailBatchController controller;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InvoiceMailBatchSnapshot>(
      valueListenable: controller,
      builder: (context, batch, _) => Row(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Sent ${batch.sent}/${batch.total} invoices'
                  '${batch.finished && batch.issues.isNotEmpty ? ' • ${batch.issues.length} issues' : ''}',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: batch.progress),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Invoice mailing details',
            onPressed: onInfo,
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _InvoiceMailJob {
  const _InvoiceMailJob({
    required this.id,
    required this.invoiceId,
    required this.recipientName,
    required this.recipientEmail,
    required this.load,
  });

  final String id;
  final String invoiceId;
  final String recipientName;
  final String recipientEmail;
  final Future<_InvoiceMailPayload> Function() load;
}

class _InvoiceMailPayload {
  const _InvoiceMailPayload({
    required this.invoiceWidget,
    required this.recipientName,
    required this.recipientEmail,
    required this.timestampLabel,
    required this.includeFeeStructure,
    required this.markPendingPayment,
    this.onProgress,
  });

  final Widget invoiceWidget;
  final String recipientName;
  final String recipientEmail;
  final String timestampLabel;
  final bool includeFeeStructure;
  final Future<void> Function() markPendingPayment;
  final ValueChanged<String>? onProgress;
}

class _InvoiceDeliveryOutcome {
  const _InvoiceDeliveryOutcome({
    required this.delivered,
    required this.serverIssues,
  });

  final bool delivered;
  final List<({String stage, String message, String? armCaseId})> serverIssues;
}

class _InvoiceMailFailure implements Exception {
  const _InvoiceMailFailure({
    required this.side,
    required this.stage,
    required this.message,
    this.armCaseId,
  });

  final InvoiceMailIssueSide side;
  final String stage;
  final String message;
  final String? armCaseId;

  @override
  String toString() => message;
}
