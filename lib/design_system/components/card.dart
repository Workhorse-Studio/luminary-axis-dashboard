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
    return Neumorphic(
      style: NeumorphicStyle(
        border: NeumorphicBorder(color: AxisColors.blackPurple20),
        color: AxisColors.blackPurple30.withValues(alpha: 0.3),
        shadowLightColor: Colors.transparent,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            SizedBox(
              width: width,
              height: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsetsGeometry.only(left: 20),
                  child: Text(
                    header,
                    style: heading2,
                  ),
                ),
              ),
            ),
            child,
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
