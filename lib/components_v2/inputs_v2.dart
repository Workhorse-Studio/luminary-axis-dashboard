import 'package:flutter/material.dart';
import 'colors_v2.dart';
import 'text_styles_v2.dart';

class StakentTextField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final VoidCallback? onSuffixTap;

  const StakentTextField({
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.obscureText = false,
    this.onSuffixTap,
    super.key,
  });

  @override
  State<StakentTextField> createState() => _StakentTextFieldState();
}

class _StakentTextFieldState extends State<StakentTextField> {
  bool isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: StakentTextStyles.labelMedium,
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused ? StakentColors.surfaceHover : StakentColors.surfaceInput,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused ? StakentColors.purplePrimary : StakentColors.borderSubtle,
              width: 1,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: StakentColors.purplePrimary.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            style: StakentTextStyles.bodyLarge.copyWith(color: StakentColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: StakentTextStyles.bodyLarge.copyWith(color: StakentColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: isFocused ? StakentColors.purplePrimary : StakentColors.textSecondary,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      child: Icon(
                        widget.suffixIcon,
                        color: StakentColors.textSecondary,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
