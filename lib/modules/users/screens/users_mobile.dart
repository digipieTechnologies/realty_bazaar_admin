// File: lib/modules/users/screens/users_mobile.dart
// Purpose: Mobile layout for Super Admin Users management screen with card list & bottom sheet filter.

import 'package:brokerflow_admin/app/app_routes.dart';
import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                    padding: const EdgeInsets.only(bottom: 32),
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
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: context.borderColor),
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
                  _buildRoleBadge(context, user.role),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: context.borderColor),
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
                    icon: Icon(Icons.edit_rounded, color: context.primaryColor, size: 20),
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
                    icon: Icon(Icons.delete_outline_rounded, color: context.errorColor, size: 20),
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

  Widget _buildRoleBadge(BuildContext context, UserRole role) {
    Color bg = context.primaryContainerColor;
    Color fg = context.primaryColor;
    if (role == UserRole.superAdmin) {
      bg = context.warningContainerColor;
      fg = context.warningColor;
    } else if (role == UserRole.marketing) {
      bg = context.secondaryContainerColor;
      fg = context.secondaryColor;
    } else if (role == UserRole.broker) {
      bg = context.primaryContainerColor;
      fg = context.primaryColor;
    } else if (role == UserRole.user) {
      bg = context.surfaceLightColor;
      fg = context.textColorMuted;
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
