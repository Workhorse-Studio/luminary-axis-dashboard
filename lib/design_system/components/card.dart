part of axis_dashboard;

class AxisCard extends StatelessWidget {
  final double? width, height;
  final Widget child;
  final String header;

  const AxisCard({
    required this.header,
    required this.width,
    required this.height,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StakentCard(
       width: width,
       height: height,
       padding: EdgeInsets.zero,
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             if (header != '')
                Padding(
                   padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
                   child: Text(header, style: StakentTextStyles.headingMedium),
                ),
             Expanded(child: child),
          ]
       )
    );
  }
}
