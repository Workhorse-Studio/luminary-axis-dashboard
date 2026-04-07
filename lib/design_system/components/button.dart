part of axis_dashboard;

class AxisButton extends StatelessWidget {
  final Widget child;
  final bool isHighlighted;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final IconData? icon;

  const AxisButton({
    required this.child,
    this.onPressed,
    this.width = double.infinity,
    this.height = double.infinity,
    this.isHighlighted = false,
    this.icon,
    super.key,
  });

  factory AxisButton.text({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    double? width,
    double? height,
    bool isHighlighted = false,
    Key? key,
  }) {
    return _AxisButtonText(
      label: label,
      onPressed: onPressed,
      icon: icon,
      width: width,
      height: height,
      isHighlighted: isHighlighted,
      key: key,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: StakentColors.surfaceInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StakentColors.borderSubtle),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _AxisButtonText extends AxisButton {
  final String label;

  _AxisButtonText({
    required this.label,
    super.onPressed,
    super.icon,
    super.width,
    super.height,
    super.isHighlighted,
    super.key,
  }) : super(child: const SizedBox());

  @override
  Widget build(BuildContext context) {
    if (isHighlighted) {
      return StakentPrimaryButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        width: width,
        height: height,
      );
    } else {
      return StakentSecondaryButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        width: width,
        height: height,
      );
    }
  }
}

class AxisNMButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AxisNMButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StakentPrimaryButton(
      label: label,
      onPressed: onPressed,
    );
  }
}
