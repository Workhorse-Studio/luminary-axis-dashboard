part of axis_dashboard;

late final ArmClient armClient;
final ArmCaptureBoundaryController armCaptureBoundaryController =
    ArmCaptureBoundaryController();
final NavigatorObserver armNavigationObserver = _ArmNavigationObserver();
String _currentArmRoute = kDebugMode ? Routes.dev.slug : Routes.login.slug;

class ArmLinkedServerFailure implements Exception {
  const ArmLinkedServerFailure({
    required this.caseId,
    this.statusCode,
    this.body,
    this.rawBody,
  });

  final String caseId;
  final int? statusCode;
  final JSON? body;
  final String? rawBody;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'caseId': caseId,
    if (statusCode != null) 'statusCode': statusCode,
    if (body != null) 'body': body,
    if (rawBody != null && rawBody!.trim().isNotEmpty) 'rawBody': rawBody,
  };

  @override
  String toString() => jsonEncode(<String, dynamic>{
    'serverArmCaseId': caseId,
    if (statusCode != null) 'statusCode': statusCode,
    if (body != null) 'body': body,
    if (rawBody != null && rawBody!.trim().isNotEmpty) 'rawBody': rawBody,
  });
}

void initializeArmClient() {
  armClient = ArmClient(
    sink: FirebaseArmSink(
      firestore: firestore,
      storage: storage,
    ),
    appId: 'luminary_axis_dashboard',
    environment: kReleaseMode ? 'production' : 'debug',
    userIdProvider: () => auth.currentUser?.uid,
    userEmailProvider: () => auth.currentUser?.email,
    routeProvider: () => _currentArmRoute,
    contextBuilder: () => <String, dynamic>{
      'role': role,
      'isAdmin': isAdmin,
      'platform': defaultTargetPlatform.name,
      if (auth.currentUser != null)
        'providers': auth.currentUser!.providerData
            .map((provider) => provider.providerId)
            .where((providerId) => providerId.isNotEmpty)
            .toList(growable: false),
    },
  );
  armClient.addBreadcrumb(
    'ARM client initialized',
    category: 'arm',
    data: <String, dynamic>{
      'environment': kReleaseMode ? 'production' : 'debug',
    },
  );
}

Future<T> runArmTrackedAction<T>({
  required String feature,
  required String operation,
  required Future<T> Function() action,
  ArmSeverity severity = ArmSeverity.low,
  String category = 'exception',
  Map<String, dynamic>? tags,
  ArmSnapshotBuilder? recoverySnapshotBuilder,
  ArmScreenshotCapture? screenshotCapture,
  bool captureScreenshot = false,
  FutureOr<void> Function(ArmCaptureResult result)? onReported,
}) {
  return _runArmTrackedAction<T>(
    feature: feature,
    operation: operation,
    action: action,
    severity: severity,
    category: category,
    tags: tags,
    recoverySnapshotBuilder: recoverySnapshotBuilder,
    screenshotCapture:
        screenshotCapture ??
        (captureScreenshot ? armCaptureBoundaryController.capturePng : null),
    onReported: onReported,
  );
}

String withArmReference(String message, String? caseId) {
  if (caseId == null || caseId.isEmpty) {
    return message;
  }
  return '$message Support reference: $caseId';
}

void showArmSnackBar(
  BuildContext context,
  String message, {
  String? caseId,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(withArmReference(message, caseId))));
}

class _ArmNavigationObserver extends NavigatorObserver {
  void _record(
    Route<dynamic>? route,
    Route<dynamic>? previousRoute,
    String verb,
  ) {
    final routeName = _nameOf(route);
    if (routeName == null) return;
    _currentArmRoute = routeName;
    armClient.addBreadcrumb(
      'Route $verb',
      category: 'navigation',
      data: <String, dynamic>{
        'route': routeName,
        if (_nameOf(previousRoute) case final String previous?)
          'previousRoute': previous,
      },
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _record(route, previousRoute, 'pushed');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _record(previousRoute, route, 'popped');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _record(newRoute, oldRoute, 'replaced');
  }

  String? _nameOf(Route<dynamic>? route) {
    final settingsName = route?.settings.name;
    if (settingsName != null && settingsName.isNotEmpty) {
      return settingsName;
    }
    return route?.runtimeType.toString();
  }
}

Future<T> _runArmTrackedAction<T>({
  required String feature,
  required String operation,
  required Future<T> Function() action,
  required ArmSeverity severity,
  required String category,
  required Map<String, dynamic>? tags,
  required ArmSnapshotBuilder? recoverySnapshotBuilder,
  required ArmScreenshotCapture? screenshotCapture,
  required FutureOr<void> Function(ArmCaptureResult result)? onReported,
}) async {
  try {
    armClient.addBreadcrumb(
      '$feature.$operation started',
      level: 'info',
      category: 'operation',
    );
    final result = await action();
    armClient.addBreadcrumb(
      '$feature.$operation completed',
      level: 'info',
      category: 'operation',
    );
    return result;
  } catch (error, stackTrace) {
    if (error is ArmLinkedServerFailure) {
      armClient.addBreadcrumb(
        '$feature.$operation linked to server ARM case',
        level: 'warn',
        category: 'arm',
        data: error.toMap(),
      );
      rethrow;
    }

    try {
      final capture = await armClient.captureException(
        error: error,
        stackTrace: stackTrace,
        feature: feature,
        operation: operation,
        severity: severity,
        category: category,
        tags: tags,
        recoverySnapshotBuilder: recoverySnapshotBuilder,
        screenshotCapture: screenshotCapture,
        handled: true,
      );
      if (onReported != null) {
        await onReported(capture);
      }
    } catch (captureError) {
      armClient.addBreadcrumb(
        'ARM capture failed: $captureError',
        level: 'error',
        category: 'arm',
      );
    }
    rethrow;
  }
}
