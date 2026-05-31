part of axis_dashboard;

class StudentInvoiceData extends JSONSerialisable {
  final String invoiceType;
  final String invoiceId;
  final double amtPayable;
  final String remarks;
  final String parentName;
  final String studentName;
  final String address;
  final String invoiceDateFormatted;
  final String terms;
  final String dueDateFormatted;
  final List<InvoiceEntry> entries;
  final InvoiceStatus invoiceStatus;

  const StudentInvoiceData({
    required this.invoiceDateFormatted,
    required this.address,
    required this.amtPayable,
    this.remarks = '',
    required this.dueDateFormatted,
    required this.entries,
    required this.invoiceId,
    required this.parentName,
    required this.studentName,
    required this.invoiceStatus,
    required this.terms,
  }) : invoiceType = 'student';

  StudentInvoiceData.fromJson(JSON json)
    : invoiceType = (json['invoiceType'] as String?) ?? 'student',
      invoiceId = json['invoiceId'] as String,
      amtPayable = (json['amtPayable'] as num).toDouble(),
      remarks = (json['remarks'] as String?) ?? '',
      parentName = json['parentName'] as String,
      studentName = json['studentName'] as String,
      address = (json['address'] as String?) ?? '',
      invoiceStatus = InvoiceStatus.fromJson(json['invoiceStatus'] as String),
      invoiceDateFormatted = json['invoiceDateFormatted'] as String,
      terms = json['terms'] as String,
      dueDateFormatted = json['dueDateFormatted'] as String,
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
    'amtPayable': amtPayable,
    'remarks': remarks,
    'parentName': parentName,
    'studentName': studentName,
    'address': address,
    'invoiceDateFormatted': invoiceDateFormatted,
    'terms': terms,
    'dueDateFormatted': dueDateFormatted,
    'invoiceStatus': invoiceStatus.name,
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
