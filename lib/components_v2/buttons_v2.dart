import 'package:flutter/material.dart';
import 'colors_v2.dart';
import 'text_styles_v2.dart';

/// Primary filled button with purple gradient
class StakentPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool isLoading;

  const StakentPrimaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.height,
    this.isLoading = false,
    super.key,
  });

  @override
  State<StakentPrimaryButton> createState() => _StakentPrimaryButtonState();
}

class _StakentPrimaryButtonState extends State<StakentPrimaryButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height ?? 48,
          decoration: BoxDecoration(
            gradient: StakentColors.purpleGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isHovering && widget.onPressed != null
                ? [
                    BoxShadow(
                      color: StakentColors.purpleGlow,
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StakentColors.textPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: StakentColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: StakentTextStyles.labelLarge.copyWith(
                          color: StakentColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class StakentSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double? height;

  const StakentSecondaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    this.height,
    super.key,
  });

  @override
  State<StakentSecondaryButton> createState() => _StakentSecondaryButtonState();
}

class _StakentSecondaryButtonState extends State<StakentSecondaryButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height ?? 48,
          decoration: BoxDecoration(
            color: isHovering
                ? StakentColors.surfaceHover
                : StakentColors.surfaceInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovering
                  ? StakentColors.borderActive
                  : StakentColors.borderSubtle,
              width: 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color: StakentColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: StakentTextStyles.labelLarge.copyWith(
                    color: StakentColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
