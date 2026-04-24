part of axis_dashboard;

class FinancialsPage extends StatefulWidget {
  const FinancialsPage({super.key});

  @override
  State<FinancialsPage> createState() => _FinancialsPageState();
}

class _FinancialsPageState extends State<FinancialsPage> {
  int year = DateTime.now().year;
  Future<FinancialData>? _financialDataFuture;

  @override
  void initState() {
    super.initState();
    _financialDataFuture = _fetchFinancialData();
  }

  Future<FinancialData> _fetchFinancialData() async {
    final invoicesSnapshot = await firestore
        .collection('global')
        .doc('archives')
        .collection('invoices')
        .where(
          'invoiceDateFormatted',
          isGreaterThanOrEqualTo: DateFormat(
            'd-M-y',
          ).format(DateTime(year, 1, 1)),
        )
        .where(
          'invoiceDateFormatted',
          isLessThanOrEqualTo: DateFormat(
            'd-M-y',
          ).format(DateTime(year, 12, 31)),
        )
        .get();

    final monthlyData = <int, MonthlyFinancials>{};
    double ytdRevenue = 0;
    double ytdPayouts = 0;

    for (final doc in invoicesSnapshot.docs) {
      final data = doc.data();
      final dateStr = data['invoiceDateFormatted'] as String?;
      if (dateStr == null) continue;
      
      final date = DateFormat('d-M-y').parse(dateStr);
      if (date.year != year) continue;

      final month = date.month;
      final invoiceType = data['invoiceType'];
      final amount = data['amtDue'] ?? data['amtPayable'] ?? 0.0;

      final monthFinancials = monthlyData.putIfAbsent(
        month,
        () => MonthlyFinancials(month),
      );

      if (invoiceType == 'student') {
        monthFinancials.revenue += amount;
        ytdRevenue += amount;
      } else if (invoiceType == 'teacher') {
        monthFinancials.payouts += amount;
        ytdPayouts += amount;
      }
    }

    return FinancialData(
      ytdRevenue: ytdRevenue,
      ytdPayouts: ytdPayouts,
      monthlyData: monthlyData.values.toList()
        ..sort((a, b) => a.month.compareTo(b.month)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navbar(
      pageTitle: 'Financials',
      actions: [
        AxisButton(
          width: 60,
          height: 60,
          onPressed: () => setState(() {
            year -= 1;
            _financialDataFuture = _fetchFinancialData();
          }),
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
                onPressed: () => setState(() {
                  year += 1;
                  _financialDataFuture = _fetchFinancialData();
                }),
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
      body: (context) => FutureBuilder<FinancialData>(
        future: _financialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                'No financial data to be shown.',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'YTD Revenue',
                      '\$${financialData.ytdRevenue.toStringAsFixed(2)}',
                      Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'YTD Payouts',
                      '\$${financialData.ytdPayouts.toStringAsFixed(2)}',
                      Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'YTD Net Profit',
                      '\$${financialData.ytdNetProfit.toStringAsFixed(2)}',
                      Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Charts
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Revenue vs Payouts', style: heading2),
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
                            Text('Net Profit Trend', style: heading2),
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

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: AxisCard(
        width: 300,
        height: 150,
        header: title,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              value,
              style: heading2.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(FinancialData financialData) {
    return Expanded(
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              financialData.monthlyData
                  .map((d) => d.revenue > d.payouts ? d.revenue : d.payouts)
                  .reduce((a, b) => a > b ? a : b) *
              1.2,
          barGroups: financialData.monthlyData
              .map(
                (data) => BarChartGroupData(
                  x: data.month,
                  barRods: [
                    BarChartRodData(
                      fromY: 0,
                      toY: data.revenue,
                      color: Colors.green,
                      width: 15,
                    ),
                    BarChartRodData(
                      fromY: 0,
                      toY: data.payouts,
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
                interval: 500,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '\$${value.toInt()}',
                      style: body2,
                    ),
                  );
                },
                reservedSize: 60,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
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
                final revenue = rodIndex == 0 ? rod.toY : group.barRods[0].toY;
                final payouts = rodIndex == 1 ? rod.toY : group.barRods[1].toY;
                return BarTooltipItem(
                  '$month\n'
                  'Revenue: \$${revenue.toStringAsFixed(2)}\n'
                  'Payouts: \$${payouts.toStringAsFixed(2)}',
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
    return Expanded(
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 500,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '\$${value.toInt()}',
                      style: body2,
                    ),
                  );
                },
                reservedSize: 60,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
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
            border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
          ),
          minX: 1,
          maxX: 12,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: financialData.monthlyData
                  .map((d) => FlSpot(d.month.toDouble(), d.netProfit))
                  .toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.3),
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
                    '$month\nNet Profit: \$${spot.y.toStringAsFixed(2)}',
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
}

class FinancialData {
  final double ytdRevenue;
  final double ytdPayouts;
  final List<MonthlyFinancials> monthlyData;

  FinancialData({
    required this.ytdRevenue,
    required this.ytdPayouts,
    required this.monthlyData,
  });

  double get ytdNetProfit => ytdRevenue - ytdPayouts;
}

class MonthlyFinancials {
  final int month;
  double revenue = 0.0;
  double payouts = 0.0;

  MonthlyFinancials(this.month);

  double get netProfit => revenue - payouts;
}
