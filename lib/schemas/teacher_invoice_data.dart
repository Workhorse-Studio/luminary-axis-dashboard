part of axis_dashboard;

class TeacherInvoiceData extends JSONSerialisable {
  static const String defaultAgencyName = 'Axis Education Centre';
  static const String defaultAddressLine1 = '9 King Albert Park #02-08';
  static const String defaultAddressLine2 = 'Singapore 598332';
  static const String defaultPhoneNum = '80626728';
  static const String defaultEmail = 'axiseducationcentre@gmail.com';

  final String invoiceId;
  final String invoiceType;
  final String agencyName;
  final String addressLine1;
  final String addressLine2;
  final String phoneNum;
  final String email;
  final double amtDue;
  final String teacherName;
  final String address;
  final String invoiceDateFormatted;
  final String dueDateFormatted;
  final InvoiceStatus invoiceStatus;
  final List<InvoiceEntry> entries;

  const TeacherInvoiceData({
    required this.invoiceDateFormatted,
    required this.address,
    required this.amtDue,
    required this.dueDateFormatted,
    required this.invoiceStatus,
    required this.entries,
    required this.invoiceId,
    required this.agencyName,
    required this.teacherName,
    required this.addressLine1,
    required this.addressLine2,
    required this.phoneNum,
    required this.email,
  }) : invoiceType = 'teacher';

  TeacherInvoiceData.fromJson(JSON json)
    : invoiceType = (json['invoiceType'] as String?) ?? 'teacher',
      invoiceId = (json['invoiceId'] as String?) ?? '',
      agencyName = (json['agencyName'] as String?) ?? defaultAgencyName,
      addressLine1 = (json['addressLine1'] as String?) ?? defaultAddressLine1,
      addressLine2 = (json['addressLine2'] as String?) ?? defaultAddressLine2,
      phoneNum = (json['phoneNum'] as String?) ?? defaultPhoneNum,
      email = (json['email'] as String?) ?? defaultEmail,
      amtDue = ((json['amtDue'] as num?) ?? 0).toDouble(),
      teacherName = (json['teacherName'] as String?) ?? '',
      address = (json['address'] as String?) ?? '',
      invoiceDateFormatted = (json['invoiceDateFormatted'] as String?) ?? '',
      dueDateFormatted =
          (json['dueDateFormatted'] as String?) ??
          (json['paidDateFormatted'] as String?) ??
          '',
      invoiceStatus = InvoiceStatus.fromJson(
        (json['invoiceStatus'] as String?) ?? InvoiceStatus.pendingBilling.name,
      ),
      entries = ((json['entries'] as List?) ?? const [])
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
    'agencyName': agencyName,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'phoneNum': phoneNum,
    'email': email,
    'amtDue': amtDue,
    'teacherName': teacherName,
    'address': address,
    'invoiceDateFormatted': invoiceDateFormatted,
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
