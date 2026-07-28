part of axis_dashboard;

const String _defaultArmIntakeUrl =
    'https://axis-server-850501828016.asia-southeast1.run.app/api/arm/intake';
const String _configuredArmIntakeUrl = String.fromEnvironment(
  'CITADEL_ARM_INTAKE_URL',
  defaultValue: _defaultArmIntakeUrl,
);
const String _configuredArmAppVersion = String.fromEnvironment(
  'CITADEL_ARM_APP_VERSION',
);
const String _configuredArmBuildNumber = String.fromEnvironment(
  'CITADEL_ARM_BUILD_NUMBER',
);
const String _configuredArmReleaseChannel = String.fromEnvironment(
  'CITADEL_ARM_RELEASE_CHANNEL',
);

String? get _armAppVersion => _nonEmptyArmValue(_configuredArmAppVersion);
String? get _armBuildNumber => _nonEmptyArmValue(_configuredArmBuildNumber);
String? get _armReleaseChannel =>
    _nonEmptyArmValue(_configuredArmReleaseChannel);

String? _nonEmptyArmValue(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

typedef ArmIntakePost =
    Future<http.Response> Function(
      Uri endpoint,
      Map<String, String> headers,
      String body,
    );

class ArmServerIntakeSink implements ArmSink {
  ArmServerIntakeSink({
    required Future<String?> Function() idTokenProvider,
    ArmIntakePost? post,
    Uri? endpoint,
  }) : _idTokenProvider = idTokenProvider,
       _post = post ?? _defaultPost,
       _endpoint = endpoint ?? _configuredEndpoint();

  factory ArmServerIntakeSink.firebaseAuth() => ArmServerIntakeSink(
    idTokenProvider: () async => await auth.currentUser?.getIdToken(),
  );

  final Future<String?> Function() _idTokenProvider;
  final ArmIntakePost _post;
  final Uri _endpoint;

  @override
  Future<ArmCaptureResult> record(ArmCaptureRequest request) async {
    final token = (await _idTokenProvider())?.trim();
    if (token == null || token.isEmpty) {
      throw StateError('ARM intake requires an authenticated Firebase user.');
    }

    final response = await _post(
      _endpoint,
      <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      jsonEncode(_encodeRequest(request)),
    );
    if (response.statusCode != 200) {
      throw StateError('ARM intake rejected the capture request.');
    }

    final decoded = _decodeResponse(response.body);
    return ArmCaptureResult(
      caseId: decoded['caseId']! as String,
      issueId: decoded['issueId']! as String,
      fingerprint: decoded['fingerprint']! as String,
      severity: decoded['severity']! as ArmSeverity,
      caseIdExposed: decoded['caseIdExposed']! as bool,
    );
  }

  static Future<http.Response> _defaultPost(
    Uri endpoint,
    Map<String, String> headers,
    String body,
  ) => http.post(endpoint, headers: headers, body: body);

  static Uri _configuredEndpoint() {
    final endpoint = Uri.tryParse(_configuredArmIntakeUrl);
    if (endpoint == null ||
        endpoint.host.isEmpty ||
        (endpoint.scheme != 'https' && endpoint.scheme != 'http')) {
      throw StateError('CITADEL_ARM_INTAKE_URL must be an absolute HTTP URL.');
    }
    if (endpoint.scheme == 'http' && endpoint.host != 'localhost') {
      throw StateError(
        'CITADEL_ARM_INTAKE_URL must use HTTPS outside localhost.',
      );
    }
    return endpoint;
  }

  Map<String, Object?> _encodeRequest(ArmCaptureRequest request) =>
      <String, Object?>{
        'version': 1,
        'severity': request.severity.wireName,
        'category': request.category,
        'feature': request.feature,
        'operation': request.operation,
        'message': request.message,
        'errorType': request.errorType,
        'stackTrace': request.stackTrace,
        'sessionId': request.sessionId,
        'breadcrumbs': request.breadcrumbs
            .map((breadcrumb) => breadcrumb.toMap())
            .toList(growable: false),
        'context': request.context,
        'tags': request.tags,
        'handled': request.handled,
        if (request.errorName != null) 'errorName': request.errorName,
        if (request.errorData != null) 'errorData': request.errorData,
        if (request.recoverySnapshot != null)
          'recoverySnapshot': request.recoverySnapshot,
        if (request.appVersion != null) 'appVersion': request.appVersion,
        if (request.buildNumber != null) 'buildNumber': request.buildNumber,
        if (request.releaseChannel != null)
          'releaseChannel': request.releaseChannel,
      };

  Map<String, Object?> _decodeResponse(String body) {
    try {
      final root = jsonDecode(body);
      if (root is! Map) throw const FormatException();
      final accepted = root['accepted'];
      final screenshot = root['screenshot'];
      final capture = root['capture'];
      if (accepted != true ||
          screenshot != 'not_supported' ||
          capture is! Map) {
        throw const FormatException();
      }
      final severity = capture['severity'];
      final caseId = capture['caseId'];
      final issueId = capture['issueId'];
      final fingerprint = capture['fingerprint'];
      final exposed = capture['caseIdExposed'];
      if (severity is! String ||
          caseId is! String ||
          issueId is! String ||
          fingerprint is! String ||
          exposed is! bool) {
        throw const FormatException();
      }
      return <String, Object?>{
        'caseId': caseId,
        'issueId': issueId,
        'fingerprint': fingerprint,
        'severity': ArmSeverity.values.byName(severity),
        'caseIdExposed': exposed,
      };
    } on FormatException {
      throw StateError('ARM intake returned an invalid capture response.');
    }
  }
}
