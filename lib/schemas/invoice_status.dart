part of axis_dashboard;

enum InvoiceStatus {
  pendingBilling('Pending Billing'),
  pendingPayment('Pending Payment'),
  pendingLatePayment('Pending Late Payment'),
  paymentReceived('Payment Received')
  ;

  final String label;

  const InvoiceStatus(this.label);

  static InvoiceStatus fromJson(String val) => switch (val) {
    'pendingBilling' => pendingBilling,
    'pendingPayment' => pendingPayment,
    'paymentReceived' => paymentReceived,
    'pendingLatePayment' => pendingLatePayment,
    String _ => throw Exception(
      'Could not parse InvoiceStatus from expression "$val"',
    ),
  };
}
