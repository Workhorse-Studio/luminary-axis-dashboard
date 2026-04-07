import 'package:flutter/material.dart';
import 'colors_v2.dart';
import 'text_styles_v2.dart';

class StakentCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool hasGradient;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const StakentCard({
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.hasGradient = false,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? StakentColors.bgElevated,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: StakentColors.borderSubtle,
          width: 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: cardContent,
        ),
      );
    }
    return cardContent;
  }
}

class StakentAssetCard extends StatelessWidget {
  final String assetName;
  final String assetSymbol;
  final String protocol;
  final double rewardRate;
  final double changePercentage;
  final IconData assetIcon;
  final Color iconColor;
  final Widget? chart;
  final VoidCallback? onTap;

  const StakentAssetCard({
    required this.assetName,
    required this.assetSymbol,
    required this.protocol,
    required this.rewardRate,
    required this.changePercentage,
    required this.assetIcon,
    required this.iconColor,
    this.chart,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercentage >= 0;

    return StakentCard(
      width: 280,
      height: 180,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  assetIcon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol,
                      style: StakentTextStyles.labelSmall,
                    ),
                    Text(
                      assetName + ' (' + assetSymbol + ')',
                      style: StakentTextStyles.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_outward,
                color: StakentColors.textTertiary,
                size: 18,
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Reward Rate',
            style: StakentTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rewardRate.toStringAsFixed(2) + '%',
                style: StakentTextStyles.statMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? StakentColors.successMuted
                      : StakentColors.errorMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (isPositive ? '+' : '') +
                      changePercentage.toStringAsFixed(2) +
                      '%',
                  style: StakentTextStyles.labelSmall.copyWith(
                    color: isPositive
                        ? StakentColors.success
                        : StakentColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (chart != null)
            SizedBox(
              height: 40,
              child: chart,
            ),
        ],
      ),
    );
  }
}

class StakentStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final double width;

  const StakentStatCard({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.width = 200,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StakentCard(
      width: width,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (iconColor ?? StakentColors.purplePrimary)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? StakentColors.purplePrimary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: StakentTextStyles.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: StakentTextStyles.statSmall,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: StakentTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
