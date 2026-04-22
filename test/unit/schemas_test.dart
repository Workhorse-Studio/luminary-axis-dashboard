import 'package:flutter_test/flutter_test.dart';
import 'package:axis_dashboard/main.dart';

void main() {
  group('Schemas Tests', () {
    test('StudentInvoiceData fromJson/toJson', () {
      final json = {
        'invoiceType': 'student',
        'invoiceId': 'INV123',
        'amtPayable': 190.0,
        'parentName': 'John Doe',
        'studentName': 'Jane Doe',
        'address': '123 Street',
        'invoiceDateFormatted': '01-01-2023',
        'terms': 'Term 1',
        'dueDateFormatted': '08-01-2023',
        'invoiceStatus': 'pendingPayment',
        'entries': [
          {
            'amt': 190.0,
            'desc': 'Class A',
            'qty': 2,
            'rate': 95.0,
          }
        ],
      };

      final data = StudentInvoiceData.fromJson(json);
      expect(data.invoiceId, 'INV123');
      expect(data.amtPayable, 190.0);
      expect(data.invoiceStatus, InvoiceStatus.pendingPayment);
      expect(data.entries.length, 1);
      expect(data.entries[0].desc, 'Class A');

      final backToJson = data.toJson();
      expect(backToJson['invoiceId'], 'INV123');
      expect(backToJson['invoiceStatus'], 'pendingPayment');
      expect(((backToJson['entries'] as List)[0] as Map)['rate'], 95.0);
    });

    test('TeacherInvoiceData fromJson/toJson', () {
      final json = {
        'invoiceType': 'teacher',
        'invoiceId': 'T-INV456',
        'amtDue': 500.0,
        'teacherName': 'Teacher Smith',
        'adminName': 'Admin User',
        'address': '456 Avenue',
        'invoiceDateFormatted': '01-02-2023',
        'invoiceStatus': 'paymentReceived',
        'terms': 'Term 2',
        'paidDateFormatted': '05-02-2023',
        'entries': [
          {
            'amt': 500.0,
            'desc': 'Teaching Hours',
            'qty': 20,
            'rate': 25.0,
          }
        ],
      };

      final data = TeacherInvoiceData.fromJson(json);
      expect(data.invoiceId, 'T-INV456');
      expect(data.amtDue, 500.0);
      expect(data.invoiceStatus, InvoiceStatus.paymentReceived);
      expect(data.entries.length, 1);

      final backToJson = data.toJson();
      expect(backToJson['invoiceId'], 'T-INV456');
      expect(backToJson['invoiceStatus'], 'paymentReceived');
    });

    test('TermData fromJson/toJson', () {
      final json = {
        'termName': 'Spring 2023',
        'termStartDate': 1672531200000,
        'termEndDate': 1680220800000,
      };

      final data = TermData.fromJson(json);
      expect(data.termName, 'Spring 2023');
      expect(data.hasEndDateSet, isTrue);

      final backToJson = data.toJson();
      expect(backToJson['termName'], 'Spring 2023');
    });

    test('StudentData fromJson/toJson', () {
      final json = {
        'role': 'student',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'invoiceIds': ['INV001', null],
        'studentContactNo': '12345678',
        'parentName': 'John Doe',
        'parentContactNo': '87654321',
        'address': 'Test Address',
        'postalCode': '123456',
        'school': 'Test School',
        'subjectCombi': 'Science',
        'withdrawn': {'ClassA': false},
      };

      final data = StudentData.fromJson(json);
      expect(data.name, 'Jane Doe');
      expect(data.invoiceIds.length, 2);
      expect(data.withdrawn['ClassA'], isFalse);

      final backToJson = data.toJson();
      expect(backToJson['name'], 'Jane Doe');
      expect((backToJson['invoiceIds'] as List).length, 2);
    });
  });
}
