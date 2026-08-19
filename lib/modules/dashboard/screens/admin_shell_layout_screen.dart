// File: lib/modules/dashboard/screens/admin_shell_layout_screen.dart
// Purpose: Responsive navigation shell layout supporting Sidebar on desktop/web/macOS
// and Bottom Navigation Bar + Drawer on mobile, bound to active user session.

import 'package:brokerflow_admin/app/app_routes.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../providers/auth/admin_auth_provider.dart';
import '../../../widgets/brand/app_logo.dart';
import '../../../widgets/common/common_app_bar.dart';
import '../../../widgets/dialogs/language_dialog.dart';
import '../../../widgets/toast/app_toast.dart';

class AdminShellLayoutScreen extends StatefulWidget {
  final Widget child;

  const AdminShellLayoutScreen({super.key, required this.child});

  @override
  State<AdminShellLayoutScreen> createState() => _AdminShellLayoutScreenState();
}

class _AdminShellLayoutScreenState extends State<AdminShellLayoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavigationItem> _navItems = [
    _NavigationItem(
      title: 'Dashboard',
      titleKey: 'dashboard',
      path: AppRoutes.dashboard,
      icon: Icons.grid_view_rounded,
    ),
    _NavigationItem(title: 'Users', titleKey: 'users', path: AppRoutes.users, icon: Icons.people_alt_rounded),
    _NavigationItem(
      title: 'Brokers',
      titleKey: 'brokers',
      path: AppRoutes.brokers,
      icon: Icons.business_rounded,
    ),
    _NavigationItem(
      title: 'Properties',
      titleKey: 'properties',
      path: AppRoutes.properties,
      icon: Icons.apartment_rounded,
    ),
    _NavigationItem(
      title: 'Video Requests',
      titleKey: 'video_requests',
      path: AppRoutes.videoRequests,
      icon: Icons.video_camera_back_rounded,
    ),
    _NavigationItem(
      title: 'Social Posts',
      titleKey: 'social_posts',
      path: AppRoutes.socialPosts,
      icon: Icons.article_rounded,
    ),
    _NavigationItem(
      title: 'Settings',
      titleKey: 'settings',
      path: AppRoutes.settings,
      icon: Icons.settings_rounded,
    ),
  ];

  int _getCurrentIndex(String location) {
    if (location.startsWith(AppRoutes.profile)) return -1;
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path)) return i;
    }
    return 0;
  }

  void _onTabSelected(int index) {
    if (!mounted) return;
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getCurrentIndex(location);
    final isDesktop = context.isDesktop;

    final adminUser = context.watch<AdminAuthProvider>().adminUser;
    final String displayName = adminUser?.name ?? adminUser?.email ?? 'Admin';
    final String displayRole = (adminUser?.role.displayName ?? 'super_admin').toUpperCase();

    if (isDesktop) {
      return Scaffold(
        key: _scaffoldKey,

        body: Row(
          children: [
            _buildSidebar(currentIndex, location.startsWith('/profile'), displayName, displayRole),
            Container(width: 1.0, color: AppColors.border),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(location),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    String mobileTitle = 'dashboard'.tr();
    if (location.startsWith(AppRoutes.profile)) {
      mobileTitle = 'action_profile'.tr();
    } else {
      for (final item in _navItems) {
        if (location.startsWith(item.path)) {
          mobileTitle = item.titleKey.tr();
          break;
        }
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 270.0,
        elevation: 0.0,
        child: _buildSidebar(currentIndex, location.startsWith(AppRoutes.profile), displayName, displayRole),
      ),
      appBar: CommonAppBar(
        title: mobileTitle,
        showBackButton: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
            onPressed: () => AppToast.showSuccess('Notifications', 'System operational.'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, left: 4.0),
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.profile),
              child: const AppLogo(size: 32.0),
            ),
          ),
        ],
      ),
      body: widget.child,
    );
  }

  Widget _buildSidebar(int currentIndex, bool isProfileSelected, String name, String role) {
    return Container(
      width: 270.0,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  const AppLogo(size: 40.0),
                  const SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BrokerFlow',
                        style: AppTextStyles.heading3.copyWith(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'growth_platform'.tr(),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28.0),
            Expanded(
              child: ListView.separated(
                itemCount: _navItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4.0),
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = index == currentIndex;
                  return _buildSidebarItem(item, isSelected, index);
                },
              ),
            ),
            // _buildLanguageSelectorButton(),
            // const SizedBox(height: 12.0),
            _buildUserCard(name, role, isProfileSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(_NavigationItem item, bool isSelected, int index) {
    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        height: 44.0,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                const SizedBox(width: 12.0),
                Icon(item.icon, size: 20.0, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 14.0),
                Text(
                  item.titleKey.tr(),
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                right: 0,
                top: 8.0,
                bottom: 8.0,
                child: Container(
                  width: 3.5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.0),
                      bottomLeft: Radius.circular(4.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectorButton() {
    return InkWell(
      onTap: () {
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
        }
        LanguageDialog.show(context);
      },
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        height: 44.0,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.translate_rounded, size: 18.0, color: AppColors.textSecondary),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                'change_language'.tr(),
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 10.0, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(String name, String role, bool isSelected) {
    final avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return InkWell(
      onTap: () {
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
        }
        context.go(AppRoutes.profile);
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : AppColors.background,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                avatarLetter,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    role,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String location) {
    String screenLabel = 'dashboard'.tr();
    if (location.startsWith(AppRoutes.profile)) {
      screenLabel = 'action_profile'.tr();
    } else {
      for (final item in _navItems) {
        if (location.startsWith(item.path)) {
          screenLabel = item.titleKey.tr();
          break;
        }
      }
    }

    return Container(
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Row(
        children: [
          Text(screenLabel, style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
            onPressed: () => AppToast.showSuccess('Notifications', 'System healthy.'),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem {
  final String title;
  final String titleKey;
  final String path;
  final IconData icon;

  const _NavigationItem({
    required this.title,
    required this.titleKey,
    required this.path,
    required this.icon,
  });
}
