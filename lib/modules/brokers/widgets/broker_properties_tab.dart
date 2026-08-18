// File: lib/modules/brokers/widgets/broker_properties_tab.dart
// Purpose: Tab child widget displaying properties owned by the selected broker using BrokerService.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/property_enums.dart';
import 'package:brokerflow_admin/models/property_model.dart';
import 'package:brokerflow_admin/modules/brokers/services/broker_service.dart';
import 'package:brokerflow_admin/widgets/common/cached_image.dart';
import 'package:brokerflow_admin/widgets/common/pagination_widget.dart';
import 'package:brokerflow_admin/widgets/common/tab_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BrokerPropertiesTab extends StatefulWidget {
  final String? brokerId;

  const BrokerPropertiesTab({super.key, required this.brokerId});

  @override
  State<BrokerPropertiesTab> createState() => _BrokerPropertiesTabState();
}

class _BrokerPropertiesTabState extends State<BrokerPropertiesTab> with AutomaticKeepAliveClientMixin {
  late Future<List<PropertyModel>> _propertiesFuture;
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  void _loadProperties() {
    final brokerId = widget.brokerId;
    if (brokerId != null && brokerId.isNotEmpty) {
      _propertiesFuture = BrokerService().getPropertiesForBroker(brokerId);
    } else {
      _propertiesFuture = Future.value([]);
    }
  }

  void _handleRefresh() {
    setState(() {
      _currentPage = 1;
      _loadProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = context.colorScheme;
    final brokerId = widget.brokerId;

    if (brokerId == null || brokerId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabHeader(title: 'tab_properties'.tr(), padding: const EdgeInsets.only(bottom: 12)),
          Expanded(
            child: Center(child: Text('no_properties_for_broker'.tr(), style: context.cardSubtitle)),
          ),
        ],
      );
    }

    return FutureBuilder<List<PropertyModel>>(
      future: _propertiesFuture,
      builder: (context, snapshot) {
        final allProperties = snapshot.data ?? [];
        final totalCount = allProperties.length;
        final totalPages = (totalCount / _pageSize).ceil().clamp(1, 999);

        // Paginated slice
        final startIndex = (_currentPage - 1) * _pageSize;
        final endIndex = (startIndex + _pageSize).clamp(0, totalCount);
        final paginatedProperties = (startIndex < totalCount)
            ? allProperties.sublist(startIndex, endIndex)
            : <PropertyModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabHeader(
              title: 'tab_properties'.tr(),
              count: snapshot.hasData ? totalCount : null,
              padding: const EdgeInsets.only(bottom: 12),
              onRefresh: _handleRefresh,
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${'common.error'.tr()}: ${snapshot.error}',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    );
                  }

                  if (allProperties.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text('no_properties_for_broker'.tr(), style: context.cardSubtitle),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: paginatedProperties.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final property = paginatedProperties[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                onTap: () {
                                  if (property.id != null) {
                                    context.go('/properties/detail/${property.id}');
                                  }
                                },
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedImage(
                                    imageUrl: property.medias.firstOrNull?.url,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  property.propertyTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${property.price.formatCurrency} • ${property.bedrooms} BHK • ${property.area} ${property.areaUnit.displayName}',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    property.propertyStatus.displayName,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      PaginationWidget(
                        currentPage: _currentPage,
                        totalPages: totalPages,
                        totalCount: totalCount,
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
