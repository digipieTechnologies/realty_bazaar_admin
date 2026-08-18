// File: lib/modules/users/screens/users_mobile.dart
// Purpose: Mobile layout for Super Admin Users management screen with card list & bottom sheet filter.

import 'package:brokerflow_admin/app/app_routes.dart';
import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/users/users_provider.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/dialogs/user_edit_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/user_filter_model.dart';
import 'users_screen.dart';

class UsersMobile extends StatelessWidget {
  final UsersScreenState state;

  const UsersMobile({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final usersProv = state.usersProv;
    final usersList = usersProv.users;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            hintText: 'search_placeholder'.tr(),
            onSearch: (query) => state.filterProvider.updateSearch(query),
            isMobile: true,
            onFilter: state.showFilterBottomSheet,
            activeFilterCount: state.filterProvider.activeFiltersCount,
          ),
          const SizedBox(height: 8),
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: UserFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: true,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: usersProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : usersList.isEmpty
                ? Center(child: Text('no_data'.tr(), style: AppTextStyles.body2))
                : ListView.separated(
                    itemCount: usersList.length,
                    padding: EdgeInsets.only(bottom: 32),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = usersList[index];
                      return _buildUserCard(context, user, usersProv);
                    },
                  ),
          ),
          PaginationWidget(
            pagination: usersProv.pagination,
            currentPage: usersProv.currentPage,
            totalPages: usersProv.totalPages,
            totalCount: usersProv.totalCount,
            isLoading: usersProv.isLoading,
            onPageChanged: (page) => usersProv.setPage(page),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, UsersProvider usersProv) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => context.pushNamed(userDetailPath, pathParameters: {'id': user.id!}, extra: user),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  user.avatarImage(context: context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name?.wordCap() ?? '-',
                          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(user.email ?? '-', style: AppTextStyles.body2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  _buildRoleBadge(user.role),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'active_status'.tr(),
                    style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Switch(
                    value: user.isActive ?? true,
                    onChanged: (val) {
                      usersProv.toggleUserStatus(user.id!);
                      AppToast.showSuccess('Status Updated', 'User status toggled.');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                    onPressed: () {
                      UserEditDialog.show(
                        context,
                        user: user,
                        onSave: (updated) {
                          usersProv.updateUser(updated);
                          AppToast.showSuccess('User Updated', 'User profile saved.');
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                    onPressed: () => state.confirmAndDeleteUser(user),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color bg = AppColors.primaryLight;
    Color fg = AppColors.primary;
    if (role == UserRole.superAdmin) {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
    } else if (role == UserRole.marketing) {
      bg = AppColors.secondaryLight;
      fg = AppColors.secondary;
    } else if (role == UserRole.broker) {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    } else if (role == UserRole.user) {
      bg = AppColors.secondaryDark.withOpacity(0.05);
      fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.0)),
      child: Text(
        role.displayName.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
