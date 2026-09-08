// File: lib/modules/users/screens/users_screen.dart
// Purpose: Entrypoint for Super Admin Users screen. Owns state and delegates UI layout to UsersDesktop or UsersMobile.

import 'package:brokerflow_admin/models/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/filters/filter_provider.dart';
import '../../../providers/users/users_provider.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/user_filter_model.dart';
import 'users_desktop.dart';
import 'users_mobile.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => UsersScreenState();
}

class UsersScreenState extends State<UsersScreen> {
  late final FilterProvider<UserFilterModel> filterProvider;
  bool showFilterSidebar = false;

  UsersProvider get usersProv => context.watch<UsersProvider>();

  @override
  void initState() {
    super.initState();
    filterProvider = FilterProvider<UserFilterModel>(
      definition: UserFilterModel.filterDefinition,
      initialFilters: const UserFilterModel(),
      onApply: () {
        final active = filterProvider.activeFilters;
        UserRole? selectedRole = active.role;
        if (active.superAdminOnly == true) {
          selectedRole = UserRole.superAdmin;
        } else if (active.brokersOnly == true) {
          selectedRole = UserRole.broker;
        }

        final resolvedFilter = active.copyWith(role: selectedRole, clearRole: selectedRole == null);

        context.read<UsersProvider>().updateFilter(resolvedFilter);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    filterProvider.dispose();
    super.dispose();
  }

  void toggleFilterSidebar() {
    setState(() {
      showFilterSidebar = !showFilterSidebar;
    });
  }

  void showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnterpriseFilterPanel(
        provider: filterProvider,
        isSidebar: false,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> confirmAndDeleteUser(UserModel user) async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'users_delete_account_title'.tr(),
      message: 'users_delete_account_msg'.tr(args: [user.name ?? 'users_fallback_name'.tr()]),
      confirmLabel: 'users_delete_confirm_btn'.tr(),
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      final success = await context.read<UsersProvider>().deleteUser(user.id!);
      if (success && mounted) {
        AppToast.showSuccess('users_toast_removed_title'.tr(), 'users_toast_removed_msg'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return UsersDesktop(state: this);
    }
    return UsersMobile(state: this);
  }
}
