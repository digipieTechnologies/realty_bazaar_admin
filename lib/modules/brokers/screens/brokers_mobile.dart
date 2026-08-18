// File: lib/modules/brokers/screens/brokers_mobile.dart
// Purpose: Mobile layout for Super Admin Brokers management screen with card list & bottom sheet filter.

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
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/dialogs/broker_edit_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/broker_filter_model.dart';
import 'brokers_screen.dart';

class BrokersMobile extends StatelessWidget {
  final BrokersScreenState state;

  const BrokersMobile({super.key, required this.state});

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
            isMobile: true,
            onFilter: state.showFilterBottomSheet,
            activeFilterCount: state.filterProvider.activeFiltersCount,
          ),
          const SizedBox(height: 8),
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: BrokerFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: true,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: brokersProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : brokersList.isEmpty
                ? Center(child: Text('no_data'.tr(), style: AppTextStyles.body2))
                : ListView.separated(
                    itemCount: brokersList.length,
                    padding: EdgeInsets.only(bottom: 32),
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final broker = brokersList[index];
                      return _buildBrokerCard(context, broker, brokersProv);
                    },
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
    );
  }

  Widget _buildBrokerCard(BuildContext context, BrokerModel broker, BrokersProvider brokersProv) {
    return InkWell(
      onTap: () => context.pushNamed(brokerDetailPath, pathParameters: {'id': broker.id!}, extra: broker),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                broker.avatarImage(radius: 18, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        broker.businessName?.wordCap() ?? 'Unnamed Broker',
                        style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Onboarding: ${broker.onboardingStatus ?? 'pending'}',
                        style: AppTextStyles.body2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildPlanBadge(broker.plan ?? 'Free'),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('active_status'.tr(), style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: broker.isActive ?? true,
                  onChanged: (val) {
                    brokersProv.toggleBrokerStatus(broker.id!);
                    AppToast.showSuccess('Broker Updated', 'Active status toggled.');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                  onPressed: () {
                    BrokerEditDialog.show(
                      context,
                      broker: broker,
                      onSave: (updated) {
                        brokersProv.updateBroker(updated);
                        AppToast.showSuccess('Broker Updated', 'Saved changes.');
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => state.confirmAndDeleteBroker(broker),
                ),
              ],
            ),
          ],
        ),
      ),
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
}
