import 'package:flutter_test/flutter_test.dart';
import 'package:axis_dashboard/main.dart';

void main() {
  group('Schemas Tests', () {
    test('StudentInvoiceData fromJson/toJson', () {
      final json = {
        'invoiceType': 'student',
        'invoiceId': 'INV123',
        'amtPayable': 190.0,
        'remarks': 'Needs invoice split by class',
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
          },
        ],
      };

      final data = StudentInvoiceData.fromJson(json);
      expect(data.invoiceId, 'INV123');
      expect(data.amtPayable, 190.0);
      expect(data.remarks, 'Needs invoice split by class');
      expect(data.invoiceStatus, InvoiceStatus.pendingPayment);
      expect(data.entries.length, 1);
      expect(data.entries[0].desc, 'Class A');

      final backToJson = data.toJson();
      expect(backToJson['invoiceId'], 'INV123');
      expect(backToJson['remarks'], 'Needs invoice split by class');
      expect(backToJson['invoiceStatus'], 'pendingPayment');
      expect(((backToJson['entries'] as List)[0] as Map)['rate'], 95.0);
    });

    test('StudentInvoiceData defaults remarks when missing', () {
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
          },
        ],
      };

      final data = StudentInvoiceData.fromJson(json);
      expect(data.remarks, '');
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
          },
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

    test('ClassData supports multi-session attendance keys', () {
      final json = {
        'name': 'Class 101',
        'students': ['s1', 's2'],
        'templateReference': 'tpl-1',
        'attendance': {
          '14-5-2026': {
            's1': 'presentOnline',
            's2': 'absent',
          },
          '14-5-2026__s002': {
            's1': 'presentPhysical',
            's2': 'presentRecording',
          },
        },
      };

      final data = ClassData.fromJson(json);
      expect(
        data.attendance['14-5-2026']!['s1'],
        AttendanceType.presentOnline,
      );
      expect(
        data.attendance['14-5-2026__s002']!['s2'],
        AttendanceType.presentRecording,
      );

      final backToJson = data.toJson();
      final attendance = backToJson['attendance'] as Map;
      expect(attendance.containsKey('14-5-2026__s002'), isTrue);
      expect(
        (attendance['14-5-2026__s002'] as Map)['s1'],
        'presentPhysical',
      );
    });

    test('ArchivedAttendanceSheet preserves session-key attendance', () {
      final sheet = ArchivedAttendanceSheet(
        timestamp: '14-5-2026 09:00:00',
        attendance: {
          '14-5-2026__s001': {
            's1': AttendanceType.presentPhysical,
          },
          '14-5-2026__s002': {
            's1': AttendanceType.absent,
          },
        },
      );

      final json = sheet.toJson();
      final reparsed = ArchivedAttendanceSheet.fromJson({
        'timestamp': json['timestamp'],
        'attendance': {
          '14-5-2026__s001': {'s1': 'presentPhysical'},
          '14-5-2026__s002': {'s1': 'absent'},
        },
      });
      expect(
        reparsed.attendance['14-5-2026__s001']!['s1'],
        AttendanceType.presentPhysical,
      );
      expect(
        reparsed.attendance['14-5-2026__s002']!['s1'],
        AttendanceType.absent,
      );
    });
  });
}
