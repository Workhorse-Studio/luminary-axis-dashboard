import 'dart:convert';

import 'package:arm_tooling/arm_tooling.dart';
import 'package:axis_dashboard/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ArmServerIntakeSink', () {
    test(
      'sends an authenticated bounded ARM contract and decodes a capture',
      () async {
        Uri? requestedEndpoint;
        Map<String, String>? requestedHeaders;
        Map<String, Object?>? payload;
        final sink = ArmServerIntakeSink(
          idTokenProvider: () async => ' firebase-id-token ',
          endpoint: Uri.parse('https://arm.example.test/api/arm/intake'),
          post: (endpoint, headers, body) async {
            requestedEndpoint = endpoint;
            requestedHeaders = headers;
            payload = (jsonDecode(body) as Map).cast<String, Object?>();
            return http.Response(
              jsonEncode(<String, Object?>{
                'accepted': true,
                'screenshot': 'not_supported',
                'capture': <String, Object?>{
                  'caseId': 'ARM-20260728-ABCDEFGH',
                  'issueId': 'ISSUE-123',
                  'fingerprint': 'fingerprint-1',
                  'severity': 'serious',
                  'caseIdExposed': true,
                },
              }),
              200,
            );
          },
        );

        final result = await sink.record(_request());

        expect(
          requestedEndpoint.toString(),
          'https://arm.example.test/api/arm/intake',
        );
        expect(requestedHeaders!['Authorization'], 'Bearer firebase-id-token');
        expect(requestedHeaders!['Content-Type'], 'application/json');
        expect(payload!['version'], 1);
        expect(payload!['severity'], 'serious');
        expect(payload!['sessionId'], 'session-1');
        expect(payload, isNot(contains('screenshot')));
        expect(result.caseId, 'ARM-20260728-ABCDEFGH');
        expect(result.severity, ArmSeverity.serious);
        expect(result.caseIdExposed, isTrue);
      },
    );

    test('refuses captures when no Firebase ID token is available', () async {
      final sink = ArmServerIntakeSink(
        idTokenProvider: () async => null,
        endpoint: Uri.parse('https://arm.example.test/api/arm/intake'),
      );

      await expectLater(
        sink.record(_request()),
        throwsA(isA<StateError>()),
      );
    });
  });
}

ArmCaptureRequest _request() => ArmCaptureRequest(
  severity: ArmSeverity.serious,
  category: 'data_integrity',
  feature: 'onboarding',
  operation: 'submit',
  message: 'StateError: submission failed',
  errorType: 'StateError',
  stackTrace: 'stack trace',
  fingerprint: 'fingerprint-1',
  sessionId: 'session-1',
  breadcrumbs: <ArmBreadcrumb>[
    ArmBreadcrumb(
      message: 'submit started',
      level: 'info',
      timestamp: DateTime.utc(2026, 7, 28),
    ),
  ],
  context: <String, dynamic>{'route': '/onboarding'},
  tags: <String, dynamic>{'source': 'dashboard'},
  handled: true,
  appVersion: '1.0.0',
  buildNumber: '1',
  releaseChannel: 'stable',
);
