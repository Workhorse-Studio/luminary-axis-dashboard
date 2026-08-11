part of axis_dashboard;

const double financialRevenueBaseline2026 = 447202.50;
final DateTime financialRevenueBaselineCutoff2026 = DateTime(2026, 7, 30);

enum FinancialBreakdown { monthly, yearly }

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
          if (!snapshot.hasData ||
              (snapshot.data!.monthlyData.isEmpty &&
                  snapshot.data!.yearlyData.isEmpty)) {
            return Center(
              child: Text(
                'No paid invoice data to be shown.',
                style: heading3,
              ),
            );
          }

          final financialData = snapshot.data!;

          return ListView(
            key: const ValueKey('financials-page-scroll'),
            padding: const EdgeInsets.all(16.0),
            children: [
              FinancialKpiCards(financialData: financialData),
              const SizedBox(height: 32),
              FinancialsCharts(financialData: financialData),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class FinancialsCharts extends StatefulWidget {
  const FinancialsCharts({required this.financialData, super.key});

  final FinancialData financialData;

  @override
  State<FinancialsCharts> createState() => _FinancialsChartsState();
}

class _FinancialsChartsState extends State<FinancialsCharts> {
  FinancialBreakdown _barBreakdown = FinancialBreakdown.monthly;
  FinancialBreakdown _lineBreakdown = FinancialBreakdown.monthly;
  final ScrollController _barScrollController = ScrollController();
  final ScrollController _lineScrollController = ScrollController();

  @override
  void dispose() {
    _barScrollController.dispose();
    _lineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _FinancialChartPanel(
        key: const ValueKey('financial-bar-chart-panel'),
        title: 'Paid Inflows vs Outflows',
        chartKeyPrefix: 'bar',
        breakdown: _barBreakdown,
        scrollController: _barScrollController,
        onBreakdownChanged: (breakdown) {
          setState(() => _barBreakdown = breakdown);
          if (_barScrollController.hasClients) {
            _barScrollController.jumpTo(0);
          }
        },
        chartBuilder: (points) => _buildBarChart(points),
        points: financialChartPoints(widget.financialData, _barBreakdown),
      ),
      const SizedBox(height: 40),
      _FinancialChartPanel(
        key: const ValueKey('financial-line-chart-panel'),
        title: 'Net Cash Flow Trend',
        chartKeyPrefix: 'line',
        breakdown: _lineBreakdown,
        scrollController: _lineScrollController,
        onBreakdownChanged: (breakdown) {
          setState(() => _lineBreakdown = breakdown);
          if (_lineScrollController.hasClients) {
            _lineScrollController.jumpTo(0);
          }
        },
        chartBuilder: (points) => _buildLineChart(points),
        points: financialChartPoints(widget.financialData, _lineBreakdown),
      ),
    ],
  );

  Widget _buildBarChart(List<FinancialChartPoint> points) {
    final scale = FinancialChartScale.fromValues(
      points.expand((point) => [point.inflows, point.outflows]),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        minY: scale.minY,
        maxY: scale.maxY,
        gridData: FlGridData(horizontalInterval: scale.interval),
        barGroups: [
          for (var index = 0; index < points.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  fromY: 0,
                  toY: points[index].inflows,
                  color: Colors.green,
                  width: 15,
                ),
                BarChartRodData(
                  fromY: 0,
                  toY: points[index].outflows,
                  color: Colors.orange,
                  width: 15,
                ),
              ],
            ),
        ],
        titlesData: _financialChartTitles(points, scale),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x];
              final baselineLabel = point.includesRevenueBaseline
                  ? '\nIncludes SGD ${financialRevenueBaseline2026.toStringAsFixed(2)} revenue through 30 Jul 2026'
                  : '';
              return BarTooltipItem(
                '${point.label}\n'
                'Paid inflows: \$${point.inflows.toStringAsFixed(2)}\n'
                'Paid outflows: \$${point.outflows.toStringAsFixed(2)}'
                '$baselineLabel',
                body2.copyWith(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<FinancialChartPoint> points) {
    final scale = FinancialChartScale.fromValues(
      points.map((point) => point.netCashFlow),
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: max(1, points.length - 1).toDouble(),
        minY: scale.minY,
        maxY: scale.maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          horizontalInterval: scale.interval,
        ),
        titlesData: _financialChartTitles(points, scale),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var index = 0; index < points.length; index++)
                FlSpot(index.toDouble(), points[index].netCashFlow),
            ],
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
                final point = points[spot.x.round()];
                return LineTooltipItem(
                  '${point.label}\nNet cash flow: \$${spot.y.toStringAsFixed(2)}',
                  body2.copyWith(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  FlTitlesData _financialChartTitles(
    List<FinancialChartPoint> points,
    FinancialChartScale scale,
  ) => FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: scale.interval,
        getTitlesWidget: _buildCurrencyAxisTitle,
        reservedSize: 68,
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.round();
          if (value != index || index < 0 || index >= points.length) {
            return const SizedBox();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(points[index].label, style: body2),
          );
        },
        reservedSize: 36,
      ),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
  );

  Widget _buildCurrencyAxisTitle(double value, TitleMeta meta) =>
      SideTitleWidget(
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

class _FinancialChartPanel extends StatelessWidget {
  const _FinancialChartPanel({
    required this.title,
    required this.chartKeyPrefix,
    required this.breakdown,
    required this.onBreakdownChanged,
    required this.scrollController,
    required this.chartBuilder,
    required this.points,
    super.key,
  });

  final String title;
  final String chartKeyPrefix;
  final FinancialBreakdown breakdown;
  final ValueChanged<FinancialBreakdown> onBreakdownChanged;
  final ScrollController scrollController;
  final Widget Function(List<FinancialChartPoint> points) chartBuilder;
  final List<FinancialChartPoint> points;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Text(title, style: heading2),
          Wrap(
            spacing: 8,
            children: [
              for (final option in FinancialBreakdown.values)
                ChoiceChip(
                  key: ValueKey('$chartKeyPrefix-${option.name}'),
                  label: Text(switch (option) {
                    FinancialBreakdown.monthly => 'Monthly',
                    FinancialBreakdown.yearly => 'Yearly',
                  }),
                  selected: breakdown == option,
                  onSelected: (_) => onBreakdownChanged(option),
                ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        height: 460,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minimumPointWidth = breakdown == FinancialBreakdown.monthly
                ? 92.0
                : 140.0;
            final chartWidth = max(
              constraints.maxWidth,
              points.length * minimumPointWidth + 96,
            );
            return Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                key: ValueKey('$chartKeyPrefix-chart-scroll'),
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  height: constraints.maxHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 16),
                    child: points.isEmpty
                        ? Center(
                            child: Text(
                              'No paid invoice data for this breakdown.',
                              style: heading3,
                            ),
                          )
                        : chartBuilder(points),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class FinancialKpiCards extends StatelessWidget {
  const FinancialKpiCards({required this.financialData, super.key});

  final FinancialData financialData;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cards = <Widget>[
        _buildStatCard(
          'YTD Paid Inflows',
          '\$${financialData.ytdInflows.toStringAsFixed(2)}',
          Colors.green,
        ),
        _buildStatCard(
          'YTD Paid Outflows',
          '\$${financialData.ytdOutflows.toStringAsFixed(2)}',
          Colors.orange,
        ),
        _buildStatCard(
          'YTD Net Cash Flow',
          '\$${financialData.ytdNetCashFlow.toStringAsFixed(2)}',
          Colors.blue,
        ),
      ];
      if (constraints.maxWidth < 900) {
        return Column(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              cards[index],
              if (index < cards.length - 1) const SizedBox(height: 16),
            ],
          ],
        );
      }
      return Row(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            Expanded(child: cards[index]),
            if (index < cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    },
  );

  Widget _buildStatCard(String title, String value, Color color) => AxisCard(
    width: double.infinity,
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
  final yearlyData = <int, YearlyFinancials>{};
  var ytdInflows = 0.0;

  final baselineYear = financialRevenueBaselineCutoff2026.year;
  final baselineMonth = financialRevenueBaselineCutoff2026.month;
  final baselineYearFinancials =
      yearlyData.putIfAbsent(
          baselineYear,
          () => YearlyFinancials(baselineYear),
        )
        ..inflows += financialRevenueBaseline2026
        ..includesRevenueBaseline = true;
  if (year == baselineYear) {
    ytdInflows = baselineYearFinancials.inflows;
    monthlyData.putIfAbsent(
        baselineMonth,
        () => MonthlyFinancials(baselineMonth),
      )
      ..inflows += financialRevenueBaseline2026
      ..includesRevenueBaseline = true;
  }

  for (final data in invoices) {
    if (data['invoiceStatus'] != InvoiceStatus.paymentReceived.name) continue;
    final date = _parseFinancialInvoiceDate(data);
    if (date == null) continue;

    final invoiceType =
        data['invoiceType'] ??
        (data.containsKey('amtPayable')
            ? 'student'
            : data.containsKey('amtDue')
            ? 'teacher'
            : null);
    // Student invoices are the current source of truth for fulfilled inflows.
    // Outflows intentionally remain untracked until a reliable source exists.
    if (invoiceType != 'student') continue;
    final amountValue = data['amtPayable'];
    if (amountValue is! num) continue;
    final amount = amountValue.toDouble();
    if (date.year == baselineYear &&
        !date.isAfter(financialRevenueBaselineCutoff2026)) {
      continue;
    }

    yearlyData
            .putIfAbsent(date.year, () => YearlyFinancials(date.year))
            .inflows +=
        amount;
    if (date.year == year) {
      final monthFinancials = monthlyData.putIfAbsent(
        date.month,
        () => MonthlyFinancials(date.month),
      );
      monthFinancials.inflows += amount;
      ytdInflows += amount;
    }
  }

  return FinancialData(
    ytdInflows: ytdInflows,
    ytdOutflows: 0,
    monthlyData: monthlyData.values.toList()
      ..sort((a, b) => a.month.compareTo(b.month)),
    yearlyData: yearlyData.values.toList()
      ..sort((a, b) => a.year.compareTo(b.year)),
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
  final List<YearlyFinancials> yearlyData;

  FinancialData({
    required this.ytdInflows,
    required this.ytdOutflows,
    required this.monthlyData,
    this.yearlyData = const <YearlyFinancials>[],
  });

  double get ytdNetCashFlow => ytdInflows - ytdOutflows;
}

class MonthlyFinancials {
  final int month;
  double inflows = 0.0;
  double outflows = 0.0;
  bool includesRevenueBaseline = false;

  MonthlyFinancials(this.month);

  double get netCashFlow => inflows - outflows;
}

class YearlyFinancials {
  final int year;
  double inflows = 0.0;
  double outflows = 0.0;
  bool includesRevenueBaseline = false;

  YearlyFinancials(this.year);

  double get netCashFlow => inflows - outflows;
}

class FinancialChartPoint {
  const FinancialChartPoint({
    required this.label,
    required this.inflows,
    required this.outflows,
    required this.includesRevenueBaseline,
  });

  final String label;
  final double inflows;
  final double outflows;
  final bool includesRevenueBaseline;

  double get netCashFlow => inflows - outflows;
}

List<FinancialChartPoint> financialChartPoints(
  FinancialData data,
  FinancialBreakdown breakdown,
) {
  if (breakdown == FinancialBreakdown.monthly) {
    final monthlyByMonth = <int, MonthlyFinancials>{
      for (final item in data.monthlyData) item.month: item,
    };
    return <FinancialChartPoint>[
      for (var month = 1; month <= 12; month++)
        FinancialChartPoint(
          label: DateFormat.MMM().format(DateTime(0, month)),
          inflows: monthlyByMonth[month]?.inflows ?? 0,
          outflows: monthlyByMonth[month]?.outflows ?? 0,
          includesRevenueBaseline:
              monthlyByMonth[month]?.includesRevenueBaseline ?? false,
        ),
    ];
  }
  return <FinancialChartPoint>[
    for (final item in data.yearlyData)
      FinancialChartPoint(
        label: item.year.toString(),
        inflows: item.inflows,
        outflows: item.outflows,
        includesRevenueBaseline: item.includesRevenueBaseline,
      ),
  ];
}
