part of axis_dashboard;

class FinancialsPage extends StatefulWidget {
  const FinancialsPage({super.key});

  @override
  State<FinancialsPage> createState() => _FinancialsPageState();
}

class _FinancialsPageState extends State<FinancialsPage> {
  int year = DateTime.now().year;
  late Stream<FinancialData> _financialDataStream;

  @override
  void initState() {
    super.initState();
    _financialDataStream = _watchFinancialData();
  }

  Stream<FinancialData> _watchFinancialData() => watchPaidFinancialData(
    database: firestore,
    year: year,
  );

  void _changeYear(int newYear) {
    setState(() {
      year = newYear;
      _financialDataStream = _watchFinancialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Financials',
      actions: [
        AxisButton(
          width: 60,
          height: 60,
          onPressed: () => _changeYear(year - 1),
          child: const Icon(
            Icons.chevron_left,
            size: 40,
          ),
        ),
        Text(
          "$year",
          style: heading3,
        ),
        (DateTime.now().year > year)
            ? AxisButton(
                width: 60,
                height: 60,
                onPressed: () => _changeYear(year + 1),
                child: const Icon(
                  Icons.chevron_right,
                  size: 40,
                ),
              )
            : const SizedBox(
                width: 60,
                height: 60,
              ),
        const SizedBox(width: 40),
      ],
      body: (context) => StreamBuilder<FinancialData>(
        stream: _financialDataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.monthlyData.isEmpty) {
            return Center(
              child: Text(
                'No paid invoice data to be shown.',
                style: heading3,
              ),
            );
          }

          final financialData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Stat Cards
                FinancialKpiCards(financialData: financialData),
                const SizedBox(height: 32),
                // Charts
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paid Inflows vs Outflows', style: heading2),
                            const SizedBox(height: 42),
                            _buildBarChart(financialData),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net Cash Flow Trend', style: heading2),
                            const SizedBox(height: 42),
                            _buildLineChart(financialData),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChart(FinancialData financialData) {
    final scale = FinancialChartScale.fromValues(
      financialData.monthlyData.expand(
        (data) => [data.inflows, data.outflows],
      ),
    );

    return Expanded(
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          minY: scale.minY,
          maxY: scale.maxY,
          gridData: FlGridData(horizontalInterval: scale.interval),
          barGroups: financialData.monthlyData
              .map(
                (data) => BarChartGroupData(
                  x: data.month,
                  barRods: [
                    BarChartRodData(
                      fromY: 0,
                      toY: data.inflows,
                      color: Colors.green,
                      width: 15,
                    ),
                    BarChartRodData(
                      fromY: 0,
                      toY: data.outflows,
                      color: Colors.orange,
                      width: 15,
                    ),
                  ],
                ),
              )
              .toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: scale.interval,
                getTitlesWidget: _buildCurrencyAxisTitle,
                reservedSize: 60,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value < 1 || value > 12) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat.MMM().format(DateTime(0, value.toInt())),
                      style: body2,
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = DateFormat.MMMM().format(
                  DateTime(0, group.x.toInt()),
                );
                final inflows = rodIndex == 0 ? rod.toY : group.barRods[0].toY;
                final outflows = rodIndex == 1 ? rod.toY : group.barRods[1].toY;
                return BarTooltipItem(
                  '$month\n'
                  'Paid inflows: \$${inflows.toStringAsFixed(2)}\n'
                  'Paid outflows: \$${outflows.toStringAsFixed(2)}',
                  body2.copyWith(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(FinancialData financialData) {
    final scale = FinancialChartScale.fromValues(
      financialData.monthlyData.map((data) => data.netCashFlow),
    );

    return Expanded(
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: 12,
          minY: scale.minY,
          maxY: scale.maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            horizontalInterval: scale.interval,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: scale.interval,
                getTitlesWidget: _buildCurrencyAxisTitle,
                reservedSize: 60,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value < 1 || value > 12) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      DateFormat.MMM().format(DateTime(0, value.toInt())),
                      style: body2,
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: financialData.monthlyData
                  .map((d) => FlSpot(d.month.toDouble(), d.netCashFlow))
                  .toList(),
              isCurved: true,
              preventCurveOverShooting: true,
              color: Colors.blue,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final month = DateFormat.MMMM().format(
                    DateTime(0, spot.x.toInt()),
                  );
                  return LineTooltipItem(
                    '$month\nNet cash flow: \$${spot.y.toStringAsFixed(2)}',
                    body2.copyWith(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyAxisTitle(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        NumberFormat.compactCurrency(
          locale: 'en_US',
          symbol: '\$',
          decimalDigits: 0,
        ).format(value),
        style: body2,
      ),
    );
  }
}

class FinancialKpiCards extends StatelessWidget {
  const FinancialKpiCards({required this.financialData, super.key});

  final FinancialData financialData;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _buildStatCard(
        'YTD Paid Inflows',
        '\$${financialData.ytdInflows.toStringAsFixed(2)}',
        Colors.green,
      ),
      const SizedBox(width: 16),
      _buildStatCard(
        'YTD Paid Outflows',
        '\$${financialData.ytdOutflows.toStringAsFixed(2)}',
        Colors.orange,
      ),
      const SizedBox(width: 16),
      _buildStatCard(
        'YTD Net Cash Flow',
        '\$${financialData.ytdNetCashFlow.toStringAsFixed(2)}',
        Colors.blue,
      ),
    ],
  );

  Widget _buildStatCard(String title, String value, Color color) => Expanded(
    child: AxisCard(
      width: 300,
      height: 150,
      header: title,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(value, style: heading2.copyWith(color: color)),
        ],
      ),
    ),
  );
}

Stream<FinancialData> watchPaidFinancialData({
  required FirebaseFirestore database,
  required int year,
}) => database
    .collection('global')
    .doc('archives')
    .collection('invoices')
    .where('invoiceStatus', isEqualTo: InvoiceStatus.paymentReceived.name)
    .snapshots()
    .map(
      (snapshot) => calculatePaidFinancialData(
        snapshot.docs.map((document) => document.data()),
        year: year,
      ),
    );

FinancialData calculatePaidFinancialData(
  Iterable<JSON> invoices, {
  required int year,
}) {
  final monthlyData = <int, MonthlyFinancials>{};
  double ytdInflows = 0;
  double ytdOutflows = 0;

  for (final data in invoices) {
    if (data['invoiceStatus'] != InvoiceStatus.paymentReceived.name) continue;
    final date = _parseFinancialInvoiceDate(data);
    if (date == null || date.year != year) continue;

    final invoiceType =
        data['invoiceType'] ??
        (data.containsKey('amtPayable')
            ? 'student'
            : data.containsKey('amtDue')
            ? 'teacher'
            : null);
    final amountValue = switch (invoiceType) {
      'student' => data['amtPayable'],
      'teacher' => data['amtDue'],
      _ => null,
    };
    if (amountValue is! num) continue;
    final amount = amountValue.toDouble();

    final monthFinancials = monthlyData.putIfAbsent(
      date.month,
      () => MonthlyFinancials(date.month),
    );
    if (invoiceType == 'student') {
      monthFinancials.inflows += amount;
      ytdInflows += amount;
    } else if (invoiceType == 'teacher') {
      monthFinancials.outflows += amount;
      ytdOutflows += amount;
    }
  }

  return FinancialData(
    ytdInflows: ytdInflows,
    ytdOutflows: ytdOutflows,
    monthlyData: monthlyData.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month)),
  );
}

DateTime? _parseFinancialInvoiceDate(JSON invoice) {
  final timestamp = invoice['invoiceDate'];
  if (timestamp is Timestamp) return timestamp.toDate();
  final formatted = invoice['invoiceDateFormatted'];
  if (formatted is! String || formatted.trim().isEmpty) return null;
  try {
    return DateFormat('d-M-y').parseStrict(formatted.trim());
  } on FormatException {
    return null;
  }
}

class FinancialData {
  final double ytdInflows;
  final double ytdOutflows;
  final List<MonthlyFinancials> monthlyData;

  FinancialData({
    required this.ytdInflows,
    required this.ytdOutflows,
    required this.monthlyData,
  });

  double get ytdNetCashFlow => ytdInflows - ytdOutflows;
}

class MonthlyFinancials {
  final int month;
  double inflows = 0.0;
  double outflows = 0.0;

  MonthlyFinancials(this.month);

  double get netCashFlow => inflows - outflows;
}
