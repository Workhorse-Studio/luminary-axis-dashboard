part of axis_dashboard;

class StudentInvoiceData extends JSONSerialisable {
  final String invoiceType;
  final String invoiceId;
  final double amtPayable;
  final String parentName;
  final String studentName;
  final String address;
  final String invoiceDateFormatted;
  final String terms;
  final String dueDateFormatted;
  final List<({double amt, String desc, double qty, double rate})> entries;

  const StudentInvoiceData({
    required this.invoiceDateFormatted,
    required this.address,
    required this.amtPayable,
    required this.dueDateFormatted,
    required this.entries,
    required this.invoiceId,
    required this.parentName,
    required this.studentName,
    required this.terms,
  }) : invoiceType = 'student';

  StudentInvoiceData.fromJson(JSON json)
    : invoiceType = json['invoiceType'] as String,
      invoiceId = json['invoiceId'] as String,
      amtPayable = json['amtPayable'] as double,
      parentName = json['parentName'] as String,
      studentName = json['studentName'] as String,
      address = json['address'] as String,
      invoiceDateFormatted = json['invoiceDateFormatted'] as String,
      terms = json['terms'] as String,
      dueDateFormatted = json['dueDateFormatted'] as String,
      entries = (json['entries'] as List)
          .map((e) => e as Map)
          .map(
            (e) => (
              amt: e['amt'] as double,
              desc: e['desc'] as String,
              qty: e['qty'] as double,
              rate: e['rate'] as double,
            ),
          )
          .toList();

  @override
  JSON toJson() => {
    'invoiceType': invoiceType,
    'invoiceId': invoiceId,
    'amtPayable': amtPayable,
    'parentName': parentName,
    'studentName': studentName,
    'address': address,
    'invoiceDateFormatted': invoiceDateFormatted,
    'terms': terms,
    'dueDateFormatted': dueDateFormatted,
    'entries': entries
        .map(
          (e) => {
            'amt': e.amt,
            'desc': e.desc,
            'qty': e.qty,
            'rate': e.rate,
          },
        )
        .toList(),
  };
}

class TeacherInvoiceData extends JSONSerialisable {
  final String invoiceId;
  final String invoiceType;
  final double amtDue;
  final String teacherName;
  final String adminName;
  final String address;
  final String invoiceDateFormatted;
  final String terms;
  final String paidDateFormatted;
  final List<({double amt, String desc, double qty, double rate})> entries;

  const TeacherInvoiceData({
    required this.invoiceDateFormatted,
    required this.address,
    required this.amtDue,
    required this.paidDateFormatted,
    required this.entries,
    required this.invoiceId,
    required this.adminName,
    required this.teacherName,
    required this.terms,
  }) : invoiceType = 'teacher';

  TeacherInvoiceData.fromJson(JSON json)
    : invoiceType = json['invoiceType'] as String,

      invoiceId = json['invoiceId'] as String,
      amtDue = json['amtDue'] as double,
      teacherName = json['teacherName'] as String,
      adminName = json['adminName'] as String,
      address = json['address'] as String,
      invoiceDateFormatted = json['invoiceDateFormatted'] as String,
      terms = json['terms'] as String,
      paidDateFormatted = json['paidDateFormatted'] as String,
      entries = (json['entries'] as List)
          .map((e) => e as Map)
          .map(
            (e) => (
              amt: e['amt'] as double,
              desc: e['desc'] as String,
              qty: e['qty'] as double,
              rate: e['rate'] as double,
            ),
          )
          .toList();

  @override
  JSON toJson() => {
    'invoiceType': invoiceType,
    'invoiceId': invoiceId,
    'amtDue': amtDue,
    'teacherName': teacherName,
    'adminName': adminName,
    'address': address,
    'invoiceDateFormatted': invoiceDateFormatted,
    'terms': terms,
    'paidDateFormatted': paidDateFormatted,
    'entries': entries
        .map(
          (e) => {
            'amt': e.amt,
            'desc': e.desc,
            'qty': e.qty,
            'rate': e.rate,
          },
        )
        .toList(),
  };
}
