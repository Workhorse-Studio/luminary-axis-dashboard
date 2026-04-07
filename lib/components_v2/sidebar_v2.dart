import 'package:flutter/material.dart';
import 'colors_v2.dart';
import 'text_styles_v2.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final bool isNew;
  final int? badgeCount;

  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
    this.isNew = false,
    this.badgeCount,
  });
}

class StakentSidebar extends StatefulWidget {
  final String logoText;
  final String? logoTagline;
  final List<NavItem> navItems;
  final String currentRoute;
  final VoidCallback? onLogout;
  final ValueChanged<String> onRouteSelected;
  final double width;
  final Widget? footer;

  const StakentSidebar({
    required this.logoText,
    this.logoTagline,
    required this.navItems,
    required this.currentRoute,
    required this.onRouteSelected,
    this.onLogout,
    this.width = 240,
    this.footer,
    super.key,
  });

  @override
  State<StakentSidebar> createState() => _StakentSidebarState();
}

class _StakentSidebarState extends State<StakentSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: StakentColors.bgSecondary,
        border: Border(
          right: BorderSide(
            color: StakentColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildLogo(),
          const SizedBox(height: 32),
          _buildTabSwitcher(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.navItems.length,
              itemBuilder: (context, index) {
                final item = widget.navItems[index];
                final isActive = widget.currentRoute == item.route;
                return _NavItemTile(
                  item: item,
                  isActive: isActive,
                  onTap: () => widget.onRouteSelected(item.route),
                );
              },
            ),
          ),
          if (widget.footer != null) ...[
            const Divider(color: StakentColors.borderSubtle),
            widget.footer!,
          ],
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: StakentColors.purpleGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: StakentColors.textPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.logoText,
                style: StakentTextStyles.brand,
              ),
              if (widget.logoTagline != null)
                Text(
                  widget.logoTagline!,
                  style: StakentTextStyles.brandTagline,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: StakentColors.surfaceInput,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: StakentColors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: StakentColors.borderSubtle,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Staking',
                    style: StakentTextStyles.labelMedium,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Stablecoin',
                    style: StakentTextStyles.labelMedium.copyWith(
                      color: StakentColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemTile extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<_NavItemTile> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? StakentColors.surfaceHover
                : isHovering
                    ? StakentColors.surfaceInput
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: widget.isActive
                ? Border.all(color: StakentColors.borderSubtle)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: widget.isActive
                    ? StakentColors.textPrimary
                    : StakentColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: widget.isActive
                      ? StakentTextStyles.navActive
                      : StakentTextStyles.navInactive,
                ),
              ),
              if (widget.item.isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: StakentColors.purpleMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'New',
                    style: StakentTextStyles.labelSmall.copyWith(
                      color: StakentColors.purplePrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
