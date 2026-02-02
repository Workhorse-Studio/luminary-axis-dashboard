part of axis_dashboard;

class AxisButton extends StatefulWidget {
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
    super.key,
  }) : icon = null;

  AxisButton.text({
    required String label,
    this.onPressed,
    this.icon,
    this.width,
    this.height,
    this.isHighlighted = false,
    super.key,
  }) : child = Padding(
         padding: const EdgeInsets.all(14),
         child: Row(
           children: [
             if (icon != null) ...[
               Icon(
                 icon,
                 color: buttonLabel.color,
               ),
               const SizedBox(width: 8),
             ],
             Text(
               label,
               style: buttonLabel,
             ),
           ],
         ),
       );

  @override
  State<StatefulWidget> createState() => AxisButtonState();
}

enum ButtonState { pressed, none, disabled }

class AxisButtonState extends State<AxisButton> {
  late ButtonState buttonState;
  bool isHovering = false;

  bool get enabled => widget.onPressed != null;

  @override
  void initState() {
    if (widget.onPressed == null) {
      buttonState = ButtonState.disabled;
    } else {
      buttonState = ButtonState.none;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor = switch (buttonState) {
      ButtonState.none =>
        widget.isHighlighted
            ? AxisColors.blackPurple30.withValues(alpha: 0.35)
            : Colors.transparent,
      ButtonState.pressed => AxisColors.blackPurple30.withValues(alpha: 0.55),
      ButtonState.disabled => AxisColors.blackPurple50.withValues(alpha: 0.5),
    };
    if (isHovering) {
      buttonColor = Color.alphaBlend(
        buttonColor,
        AxisColors.blackPurple30.withValues(alpha: 0.4),
      );
    }
    return GestureDetector(
      onTapDown: (_) {
        if (!enabled) return;
        buttonState = ButtonState.pressed;
        setState(() {});
      },
      onTapUp: (_) {
        if (!enabled) return;
        buttonState = ButtonState.none;
        setState(() {});
        widget.onPressed?.call();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (!enabled) return;
          setState(() {
            isHovering = true;
          });
        },
        onExit: (_) {
          if (!enabled) return;
          setState(() {
            isHovering = false;
          });
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuint,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(16),
              border: widget.isHighlighted
                  ? Border(
                      right: BorderSide(
                        width: 2,
                        color: AxisColors.lilacPurple20.withValues(alpha: 0.2),
                      ),
                    )
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
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
    return NeumorphicButton(
      style: NeumorphicStyle(
        boxShape: NeumorphicBoxShape.stadium(),
        border: NeumorphicBorder(color: AxisColors.blackPurple20),
        color: AxisColors.blackPurple30.withValues(alpha: 0.3),
        shadowLightColor: AxisColors.blackPurple20.withValues(alpha: 0.7),
      ),
      padding: const EdgeInsets.all(0),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsetsGeometry.all(12),
        child: Text(
          label,
          style: buttonLabel,
        ),
      ),
    );
  }
}
