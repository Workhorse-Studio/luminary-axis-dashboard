import 'package:flutter/material.dart';
import 'colors_v2.dart';
import 'text_styles_v2.dart';

class StakentTabs extends StatefulWidget {
  final List<String> tabs;
  final int initialIndex;
  final ValueChanged<int> onChanged;

  const StakentTabs({
    required this.tabs,
    required this.onChanged,
    this.initialIndex = 0,
    super.key,
  });

  @override
  State<StakentTabs> createState() => _StakentTabsState();
}

class _StakentTabsState extends State<StakentTabs> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: StakentColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(widget.tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
              widget.onChanged(index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? StakentColors.purplePrimary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                widget.tabs[index],
                style: isSelected
                    ? StakentTextStyles.labelMedium.copyWith(color: StakentColors.purplePrimary)
                    : StakentTextStyles.labelMedium.copyWith(color: StakentColors.textSecondary),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StakentBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? backgroundColor;

  const StakentBadge({
    required this.text,
    this.color,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? StakentColors.purpleMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: StakentTextStyles.labelSmall.copyWith(
          color: color ?? StakentColors.purplePrimary,
        ),
      ),
    );
  }
}

class StakentDropdown extends StatelessWidget {
  final String label;
  final IconData? icon;

  const StakentDropdown({
    required this.label,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: StakentColors.surfaceInput,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StakentColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: StakentColors.textSecondary),
            const SizedBox(width: 8),
          ],
          Text(label, style: StakentTextStyles.bodyMedium),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, size: 16, color: StakentColors.textSecondary),
        ],
      ),
    );
  }
}
