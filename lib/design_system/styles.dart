part of axis_dashboard;

final menuEntryStyle = ButtonStyle(
  foregroundColor: WidgetStatePropertyAll(
    StakentColors.textPrimary,
  ),
  textStyle: WidgetStatePropertyAll(StakentTextStyles.labelMedium),
  backgroundColor: WidgetStateColor.resolveWith((states) {
    if (states.contains(WidgetState.hovered)) {
      return StakentColors.surfaceHover;
    } else {
      return StakentColors.surfaceInput;
    }
  }),
);

final BoxDecoration dialogForegroundDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: StakentColors.borderSubtle),
  color: StakentColors.bgElevated,
);

Widget axisIcon(IconData iconData) => Icon(
  iconData,
  color: StakentColors.textSecondary,
);
