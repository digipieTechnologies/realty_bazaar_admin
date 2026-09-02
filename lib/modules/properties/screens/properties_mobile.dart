// File: lib/modules/properties/screens/properties_mobile.dart
// Purpose: Mobile layout for Super Admin Properties management screen with MakeMyTrip-style vertical property cards copied from brokerflow-app.

import 'package:brokerflow_admin/app/app_routes.dart';
import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/widgets/dialogs/property_edit_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_text_styles.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/images/cached_image.dart';
import '../models/property_filter_model.dart';
import 'admin_properties_screen.dart';

class PropertiesMobile extends StatelessWidget {
  final AdminPropertiesScreenState state;

  const PropertiesMobile({super.key, required this.state});

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
            isMobile: true,
            onFilter: state.showFilterBottomSheet,
            activeFilterCount: state.filterProvider.activeFiltersCount,
            addLabel: 'Add Property',
            onAdd: () {
              PropertyEditDialog.show(context);
            },
          ),
          const SizedBox(height: 8),
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: PropertyFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: true,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? Center(child: Text('no_data'.tr(), style: AppTextStyles.body2))
                : ListView.separated(
                    itemCount: list.length,
                    padding: const EdgeInsets.only(bottom: 32),
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final property = list[index];
                      return _buildPropertyCard(context, property, prov);
                    },
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
    );
  }

  /// MakeMyTrip Vertical Card Layout copied and adapted from brokerflow-app
  Widget _buildPropertyCard(BuildContext context, PropertyModel property, AdminPropertyProvider prov) {
    final imageUrl = property.medias.isNotEmpty ? property.medias.first.url : null;
    final addressText =
        property.address?.fullAddress ??
        '${property.address?.city ?? "Surat"}, ${property.address?.state ?? "Gujarat"}';
    final formattedPrice = property.price.formatCurrency;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: context.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: () =>
              context.pushNamed(propertyDetailPath, pathParameters: {'id': property.id!}, extra: property),
          borderRadius: BorderRadius.circular(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGE CONTAINER WITH BADGES
              Stack(
                children: [
                  CachedImage(
                    imageUrl: imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    backgroundColor: colorScheme.surface,
                    errorWidget: (_) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.apartment_rounded, color: context.infoColor, size: 18),
                      );
                    },
                    placeholderWidget: (_) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.apartment_rounded, color: context.infoColor, size: 18),
                      );
                    },
                  ),

                  // Top Floating Badges: Status (Left)
                  Positioned(top: 10, left: 10, child: _buildStatusBadge(context, property.propertyStatus)),

                  // Bottom Photo Counter Badge
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 12.0),
                          const SizedBox(width: 4.0),
                          Text(
                            '${property.medias.isNotEmpty ? property.medias.length : 1} Photos',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. CARD BODY CONTENT
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            property.propertyTitle.wordCap(),
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: context.textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedPrice,
                              style: AppTextStyles.heading3.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.primaryColor,
                                fontSize: 17.0,
                              ),
                            ),
                            Text(
                              property.listingType.displayName,
                              style: AppTextStyles.caption.copyWith(
                                color: context.textColorMuted,
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Location Line
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14.0, color: context.primaryColor),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            addressText,
                            style: AppTextStyles.body2.copyWith(
                              color: context.textColorMuted,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    // Key Feature Chips Row
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: [
                        _buildChip(
                          label: property.listingType.displayName.toUpperCase(),
                          color: context.primaryColor,
                          isOutline: true,
                        ),
                        _buildChip(
                          label: property.propertyType.displayName,
                          color: context.textColorMuted,
                          isOutline: true,
                        ),
                        _buildChip(
                          label: property.constructionStatus.displayName,
                          color: context.successColor,
                          isOutline: false,
                        ),
                        if (property.furnishingStatus != FurnishingStatus.unknown)
                          _buildChip(
                            label: property.furnishingStatus.displayName,
                            color: context.textColorMuted,
                            isOutline: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12.0),

                    Divider(height: 1.0, color: context.borderColor),
                    const SizedBox(height: 10.0),

                    // Specs Wrap
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 12.0,
                            runSpacing: 6.0,
                            children: [
                              _buildSpecIconText(context, Icons.king_bed_outlined, '${property.bedrooms} Beds'),
                              _buildSpecIconText(context, Icons.bathtub_outlined, '${property.bathrooms} Baths'),
                              _buildSpecIconText(
                                context,
                                Icons.square_foot_outlined,
                                '${property.area} ${property.areaUnit.displayName}',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: context.errorColor, size: 20),
                          onPressed: () => state.confirmAndDeleteProperty(property),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip({required String label, required Color color, required bool isOutline}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: isOutline ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: isOutline ? color.withValues(alpha: 0.3) : Colors.transparent, width: 1.0),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: color, fontSize: 10.0, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSpecIconText(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: context.textColorMuted),
        const SizedBox(width: 4.0),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: context.textColor,
            fontWeight: FontWeight.w500,
            fontSize: 11.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, PropertyStatus status) {
    final isAvailable = status == PropertyStatus.available;
    final badgeColor = isAvailable ? context.successColor : context.warningColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
