part of axis_dashboard;

final menuEntryStyle = ButtonStyle(
  foregroundColor: WidgetStatePropertyAll(
    AxisColors.lilacPurple20,
  ),
  textStyle: WidgetStatePropertyAll(buttonLabel),
  backgroundColor: WidgetStateColor.resolveWith((states) {
    if (states.contains(WidgetState.hovered)) {
      return Color.alphaBlend(
        AxisColors.lilacPurple20.withValues(alpha: 0.1),
        AxisColors.blackPurple30,
      );
    } else {
      return AxisColors.blackPurple30;
    }
  }),
);

final BoxDecoration dialogForegroundDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: AxisColors.blackPurple20),
);
