part of axis_dashboard;

class TeacherInvoiceData extends JSONSerialisable {
  final String invoiceId;
  final String invoiceType;
  final double amtDue;
  final String teacherName;
  final String adminName;
  final String address;
  final String invoiceDateFormatted;
  final InvoiceStatus invoiceStatus;
  final String terms;
  final String paidDateFormatted;
  final List<InvoiceEntry> entries;

  const TeacherInvoiceData({
    required this.invoiceDateFormatted,
    required this.address,
    required this.amtDue,
    required this.paidDateFormatted,
    required this.invoiceStatus,
    required this.entries,
    required this.invoiceId,
    required this.adminName,
    required this.teacherName,
    required this.terms,
  }) : invoiceType = 'teacher';

  TeacherInvoiceData.fromJson(JSON json)
    : invoiceType = (json['invoiceType'] as String?) ?? 'teacher',
      invoiceId = json['invoiceId'] as String,
      amtDue = (json['amtDue'] as num).toDouble(),
      teacherName = json['teacherName'] as String,
      adminName = json['adminName'] as String,
      address = (json['address'] as String?) ?? '',
      invoiceDateFormatted = json['invoiceDateFormatted'] as String,
      invoiceStatus = InvoiceStatus.fromJson(json['invoiceStatus'] as String),
      terms = json['terms'] as String,
      paidDateFormatted = json['paidDateFormatted'] as String,
      entries = (json['entries'] as List)
          .map((e) => e as Map)
          .map(
            (e) => (
              amt: (e['amt'] as num).toDouble(),
              desc: e['desc'] as String,
              qty: (e['qty'] as num).toInt(),
              rate: (e['rate'] as num).toDouble(),
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
    'invoiceStatus': invoiceStatus.name,
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
