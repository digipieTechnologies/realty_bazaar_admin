// File: lib/modules/users/screens/users_desktop.dart
// Purpose: Desktop layout for Super Admin Users management screen with AppDataTable and Filter Sidebar.

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
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/dialogs/user_edit_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/user_filter_model.dart';
import 'users_screen.dart';

class UsersDesktop extends StatelessWidget {
  final UsersScreenState state;

  const UsersDesktop({super.key, required this.state});

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
            isMobile: false,
            onFilter: state.toggleFilterSidebar,
            activeFilterCount: state.filterProvider.activeFiltersCount,
          ),
          const SizedBox(height: 8),
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: UserFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: false,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: AppDataTable(
                          isLoading: usersProv.isLoading,
                          columns: [
                            AppDataColumn(label: 'users'.tr(), flex: 2),
                            AppDataColumn(label: 'email'.tr(), flex: 2),
                            AppDataColumn(label: 'role'.tr(), flex: 1.5),
                            AppDataColumn(label: 'status_active'.tr(), flex: 1.2),
                            AppDataColumn(label: 'actions'.tr(), flex: 1),
                          ],
                          rows: usersList.map((user) => _buildRow(context, user, usersProv)).toList(),
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
                ),
                if (state.showFilterSidebar) ...[
                  const SizedBox(width: 16),
                  EnterpriseFilterPanel(
                    provider: state.filterProvider,
                    isSidebar: true,
                    onClose: state.toggleFilterSidebar,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRowItem _buildRow(BuildContext context, UserModel user, UsersProvider usersProv) {
    return DataRowItem(
      cells: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              user.avatarImage(context: context, width: 40, height: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name?.wordCap() ?? '-',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.phone ?? '-',
                      style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCellText(text: user.email ?? '-'),
        Align(alignment: Alignment.centerLeft, child: _buildRoleBadge(user.role)),
        Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: user.isActive ?? true,
            onChanged: (val) {
              usersProv.toggleUserStatus(user.id!);
              AppToast.showSuccess('Status Updated', 'User status toggled.');
            },
          ),
        ),
        DataCellActions(
          onView: () => context.pushNamed(userDetailPath, pathParameters: {'id': user.id!}, extra: user),
          onEdit: () {
            UserEditDialog.show(
              context,
              user: user,
              onSave: (updated) {
                usersProv.updateUser(updated);
                AppToast.showSuccess('User Updated', 'User profile saved.');
              },
            );
          },
          onDelete: () => state.confirmAndDeleteUser(user),
        ),
      ],
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
