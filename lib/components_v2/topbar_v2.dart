import 'package:flutter/material.dart';
import 'colors_v2.dart';
import 'text_styles_v2.dart';

class StakentTopbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userAvatarUrl;
  final String userName;
  final String userStatus;
  final Widget? trailing;

  const StakentTopbar({
    required this.title,
    required this.userAvatarUrl,
    required this.userName,
    this.userStatus = 'PRO',
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: StakentColors.bgSecondary,
        border: Border(
          bottom: BorderSide(
            color: StakentColors.borderSubtle,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb or Title
          Icon(Icons.dashboard, color: StakentColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: StakentTextStyles.headingMedium,
          ),
          
          const Spacer(),
          
          // Network selector (simplified for UI)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: StakentColors.surfaceInput,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: StakentColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: StakentColors.textSecondary),
                const SizedBox(width: 8),
                Text('stakent.com', style: StakentTextStyles.bodyMedium),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: StakentColors.textSecondary),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Action Icons
          _buildIconButton(Icons.notifications_outlined, badge: 2),
          const SizedBox(width: 12),
          _buildSearchBox(),
          const SizedBox(width: 12),
          _buildIconButton(Icons.settings_outlined),
          const SizedBox(width: 24),
          
          // User Profile
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {int? badge}) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: StakentColors.surfaceInput,
            shape: BoxShape.circle,
            border: Border.all(color: StakentColors.borderSubtle),
          ),
          child: Icon(icon, color: StakentColors.textSecondary, size: 20),
        ),
        if (badge != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: StakentColors.purplePrimary,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: 120,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: StakentColors.surfaceInput,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StakentColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: StakentColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text('Search...', style: StakentTextStyles.bodyMedium.copyWith(color: StakentColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: StakentColors.surfaceInput,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StakentColors.borderSubtle),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: StakentColors.purpleMuted,
            child: Icon(Icons.person, size: 20, color: StakentColors.purplePrimary),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('@username', style: StakentTextStyles.labelSmall),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: StakentColors.surfaceHover,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('PRO', style: TextStyle(fontSize: 8, color: StakentColors.textSecondary)),
                  ),
                ],
              ),
              Text(userName, style: StakentTextStyles.labelMedium),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down, color: StakentColors.textSecondary, size: 16),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
