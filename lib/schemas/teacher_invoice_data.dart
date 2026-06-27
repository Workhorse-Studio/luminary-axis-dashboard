part of axis_dashboard;

class TeacherInvoiceData extends JSONSerialisable {
  final String invoiceId;
  final String invoiceType;
  final String agencyName;
  final String agencyContact;
  final String agencyEmail;
  final String agencyAddress;
  final double amtDue;
  final String invoiceDateFormatted;
  final String dueDateFormatted;
  final InvoiceStatus invoiceStatus;
  final List<InvoiceEntry> entries;

  const TeacherInvoiceData({
    required this.invoiceDateFormatted,
    required this.amtDue,
    required this.dueDateFormatted,
    required this.invoiceStatus,
    required this.entries,
    required this.invoiceId,
    required this.agencyName,
    required this.agencyContact,
    required this.agencyEmail,
    required this.agencyAddress,
  }) : invoiceType = 'teacher';

  TeacherInvoiceData.fromJson(JSON json)
    : invoiceType = (json['invoiceType'] as String?) ?? 'teacher',
      invoiceId = (json['invoiceId'] as String?) ?? '',
      agencyName = (json['agencyName'] as String?) ?? '',
      agencyContact = (json['agencyContact'] as String?) ?? '',
      agencyEmail = (json['agencyEmail'] as String?) ?? '',
      agencyAddress = (json['agencyAddress'] as String?) ?? '',
      amtDue = ((json['amtDue'] as num?) ?? 0).toDouble(),
      invoiceDateFormatted = (json['invoiceDateFormatted'] as String?) ?? '',
      dueDateFormatted = (json['dueDateFormatted'] as String?) ?? '',
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

  TeacherInvoiceData withAgencyDetailsFromTeacher(TeacherData teacherData) =>
      TeacherInvoiceData(
        invoiceDateFormatted: invoiceDateFormatted,
        amtDue: amtDue,
        dueDateFormatted: dueDateFormatted,
        invoiceStatus: invoiceStatus,
        entries: entries,
        invoiceId: invoiceId,
        agencyName: teacherData.agencyName.isNotEmpty
            ? teacherData.agencyName
            : teacherData.name,
        agencyContact: teacherData.agencyContact,
        agencyEmail: teacherData.agencyEmail,
        agencyAddress: teacherData.agencyAddress,
      );

  @override
  JSON toJson() => {
    'invoiceType': invoiceType,
    'invoiceId': invoiceId,
    'agencyName': agencyName,
    'agencyContact': agencyContact,
    'agencyEmail': agencyEmail,
    'agencyAddress': agencyAddress,
    'amtDue': amtDue,
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
