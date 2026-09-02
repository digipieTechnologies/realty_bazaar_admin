// File: lib/modules/brokers/screens/broker_detail_desktop.dart
// Purpose: Desktop view for Broker Detail screen modularized with standalone tab widgets.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/broker_model.dart';
import 'package:brokerflow_admin/providers/brokers/brokers_provider.dart';
import 'package:brokerflow_admin/widgets/common/app_breadcrumbs.dart';
import 'package:brokerflow_admin/widgets/dialogs/broker_edit_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/broker_detail_desktop_overview_tab.dart';
import '../widgets/broker_detail_sidebar_card.dart';
import '../widgets/broker_posts_tab.dart';
import '../widgets/broker_properties_tab.dart';

class BrokerDetailDesktop extends StatefulWidget {
  final BrokerModel broker;
  final BrokersProvider brokersProv;
  final Future<void> Function() onDelete;

  const BrokerDetailDesktop({
    super.key,
    required this.broker,
    required this.brokersProv,
    required this.onDelete,
  });

  @override
  State<BrokerDetailDesktop> createState() => _BrokerDetailDesktopState();
}

class _BrokerDetailDesktopState extends State<BrokerDetailDesktop> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final broker = widget.broker;

    return Column(
      children: [
        // Top Header Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.go('/brokers'),
                tooltip: 'common_back_tooltip'.tr(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBreadcrumbs(
                      padding: EdgeInsets.zero,
                      items: [
                        BreadcrumbItem(label: 'brokers'.tr(), route: '/brokers'),
                        BreadcrumbItem(label: broker.id ?? 'brokers_details'.tr()),
                      ],
                    ),
                    Text(broker.businessName ?? 'brokers_details'.tr(), style: context.appBarTitle),
                  ],
                ),
              ),
              // Top Right Actions Toolbar
              OutlinedButton.icon(
                onPressed: () => widget.onDelete(),
                icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error, size: 18),
                label: Text('brokers_delete_broker'.tr(), style: TextStyle(color: colorScheme.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  BrokerEditDialog.show(
                    context,
                    broker: broker,
                    onSave: (updated) => widget.brokersProv.updateBroker(updated),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text('brokers_edit_broker'.tr()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Tab Bar Header Navigation
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(text: 'tab_overview'.tr()),
              Tab(text: 'tab_properties'.tr()),
              Tab(text: 'tab_posts'.tr()),
            ],
          ),
        ),

        const Divider(height: 1),

        // Main Desktop Two-Column Split Body Layout
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Master Sidebar Card (Fixed Width)
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(child: BrokerDetailSidebarCard(broker: broker)),
                ),
                const SizedBox(width: 24),

                // Right Column - Tab Panes Content Area (Flexible)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
                    ),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        BrokerDetailDesktopOverviewTab(broker: broker),
                        BrokerPropertiesTab(brokerId: broker.id),
                        BrokerPostsTab(brokerId: broker.id),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
