// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    print('Production smoke report: ${jsonEncode(data)}');
    await writeResponseData(
      data,
      testOutputFilename: 'production_invoicing_smoke',
    );
  },
);
