// File: lib/modules/brokers/screens/brokers_desktop.dart
// Purpose: Desktop layout for Super Admin Brokers management screen with AppDataTable and Filter Sidebar.

import 'package:brokerflow_admin/app/app_routes.dart';
import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/brokers/brokers_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/dialogs/broker_edit_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/broker_filter_model.dart';
import 'brokers_screen.dart';

class BrokersDesktop extends StatelessWidget {
  final BrokersScreenState state;

  const BrokersDesktop({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final brokersProv = state.brokersProv;
    final brokersList = brokersProv.brokers;

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
            fields: BrokerFilterModel.filterDefinition.fields
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
                          isLoading: brokersProv.isLoading,
                          columns: [
                            AppDataColumn(label: 'business_name'.tr(), flex: 2),
                            AppDataColumn(label: 'plan'.tr(), flex: 1.5),
                            AppDataColumn(label: 'onboarding_status'.tr(), flex: 1.5),
                            AppDataColumn(label: 'active_status'.tr(), flex: 1.2),
                            AppDataColumn(label: 'actions'.tr(), flex: 1),
                          ],
                          rows: brokersList.map((broker) => _buildRow(context, broker, brokersProv)).toList(),
                        ),
                      ),
                      PaginationWidget(
                        pagination: brokersProv.pagination,
                        currentPage: brokersProv.currentPage,
                        totalPages: brokersProv.totalPages,
                        totalCount: brokersProv.totalCount,
                        isLoading: brokersProv.isLoading,
                        onPageChanged: (page) => brokersProv.setPage(page),
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

  DataRowItem _buildRow(BuildContext context, BrokerModel broker, BrokersProvider brokersProv) {
    return DataRowItem(
      cells: [
        Row(
          children: [
            broker.avatarImage(context: context, width: 40, height: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                broker.businessName?.wordCap() ?? 'Unnamed Broker',
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Align(alignment: Alignment.centerLeft, child: _buildPlanBadge(broker.plan ?? 'Free')),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildStatusBadge(broker.onboardingStatus ?? 'pending'),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            value: broker.isActive ?? true,
            onChanged: (val) {
              brokersProv.toggleBrokerStatus(broker.id!);
              AppToast.showSuccess('Broker Updated', 'Active status toggled.');
            },
          ),
        ),
        DataCellActions(
          onView: () =>
              context.pushNamed(brokerDetailPath, pathParameters: {'id': broker.id!}, extra: broker),
          onEdit: () {
            BrokerEditDialog.show(
              context,
              broker: broker,
              onSave: (updated) {
                brokersProv.updateBroker(updated);
                AppToast.showSuccess('Broker Updated', 'Saved changes.');
              },
            );
          },
          onDelete: () => state.confirmAndDeleteBroker(broker),
        ),
      ],
    );
  }

  Widget _buildPlanBadge(String plan) {
    Color bg = AppColors.surfaceLight;
    Color fg = AppColors.textSecondary;
    if (plan == 'Enterprise') {
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
    } else if (plan == 'Pro') {
      bg = AppColors.secondaryLight;
      fg = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.0)),
      child: Text(
        plan.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.warningLight;
    Color fg = AppColors.warning;
    if (status.toLowerCase() == 'completed') {
      bg = AppColors.successLight;
      fg = AppColors.success;
    } else if (status.toLowerCase() == 'rejected') {
      bg = AppColors.errorLight;
      fg = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.0)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
