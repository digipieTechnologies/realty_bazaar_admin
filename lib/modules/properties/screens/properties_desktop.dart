// File: lib/modules/properties/screens/properties_desktop.dart
// Purpose: Desktop layout for Super Admin Properties management screen with AppDataTable and Filter Sidebar.

import 'package:brokerflow_admin/app/app_routes.dart';
import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/widgets/common/pagination_widget.dart';
import 'package:brokerflow_admin/widgets/dialogs/property_edit_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../models/property_filter_model.dart';
import 'admin_properties_screen.dart';

class PropertiesDesktop extends StatelessWidget {
  final AdminPropertiesScreenState state;

  const PropertiesDesktop({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final prov = state.propertyProv;
    final list = prov.properties;

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
            fields: PropertyFilterModel.filterDefinition.fields
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
                          isLoading: prov.isLoading,
                          columns: [
                            AppDataColumn(label: 'properties_title'.tr(), flex: 2),
                            AppDataColumn(label: 'type'.tr()),
                            AppDataColumn(label: 'properties_listing_type'.tr()),
                            AppDataColumn(label: 'price'.tr(), flex: 1.2),
                            AppDataColumn(label: 'status'.tr()),
                            AppDataColumn(label: 'actions'.tr()),
                          ],
                          rows: list.map((prop) => _buildRow(context, prop, prov)).toList(),
                        ),
                      ),
                      PaginationWidget(
                        pagination: prov.pagination,
                        currentPage: prov.currentPage,
                        totalPages: prov.totalPages,
                        totalCount: prov.totalCount,
                        isLoading: prov.isLoading,
                        onPageChanged: (page) => prov.setPage(page),
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

  DataRowItem _buildRow(BuildContext context, PropertyModel prop, AdminPropertyProvider prov) {
    return DataRowItem(
      cells: [
        Row(
          children: [
            prop.propertyImage(context: context),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                prop.propertyTitle.wordCap(),
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        DataCellText(text: prop.propertyType.displayName, style: context.theme.textTheme.bodyLarge),
        Align(alignment: Alignment.centerLeft, child: _buildListingTypeBadge(prop.listingType.displayName)),
        DataCellText(
          text: prop.price.formatCurrency,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(prop.propertyStatus)),
        DataCellActions(
          onView: () => context.pushNamed(propertyDetailPath, pathParameters: {'id': prop.id!}, extra: prop),
          onEdit: () {
            final propertiesProv = context.read<AdminPropertyProvider>();
            PropertyEditDialog.show(
              context,
              property: prop,
              onSave: (updated) => propertiesProv.updateProperty(updated),
            );
          },
          onDelete: () => state.confirmAndDeleteProperty(prop),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(PropertyStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case PropertyStatus.available:
        bg = AppColors.successLight;
        fg = AppColors.success;
        break;
      case PropertyStatus.sold:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        break;
      case PropertyStatus.rented:
        bg = AppColors.infoLight;
        fg = AppColors.info;
        break;
      case PropertyStatus.underOffer:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        break;
      default:
        bg = AppColors.infoLight;
        fg = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.0)),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildListingTypeBadge(String listingType) {
    final isRent = listingType.toLowerCase() == 'rent';
    final bg = isRent ? AppColors.secondaryLight : AppColors.primaryLight;
    final fg = isRent ? AppColors.secondary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.0)),
      child: Text(
        listingType.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
