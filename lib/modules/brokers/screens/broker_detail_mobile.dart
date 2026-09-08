// File: lib/modules/brokers/screens/broker_detail_mobile.dart
// Purpose: Mobile layout for Broker Detail screen with Overview, Properties, and Posts tabs.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/broker_model.dart';
import 'package:brokerflow_admin/providers/brokers/brokers_provider.dart';
import 'package:brokerflow_admin/widgets/dialogs/broker_edit_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/broker_detail_overview_tab.dart';
import '../widgets/broker_posts_tab.dart';
import '../widgets/broker_properties_tab.dart';

class BrokerDetailMobile extends StatelessWidget {
  final BrokerModel broker;
  final BrokersProvider brokersProv;
  final Future<void> Function() onDelete;

  const BrokerDetailMobile({
    super.key,
    required this.broker,
    required this.brokersProv,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(broker.businessName ?? 'brokers_details'.tr()),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                BrokerEditDialog.show(
                  context,
                  broker: broker,
                  onSave: (updated) => brokersProv.updateBroker(updated),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              onPressed: () => onDelete(),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: [
              Tab(text: 'tab_overview'.tr()),
              Tab(text: 'tab_properties'.tr()),
              Tab(text: 'tab_posts'.tr()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Overview Tab
            BrokerDetailOverviewTab(broker: broker),

            // Properties Tab
            BrokerPropertiesTab(brokerId: broker.id),

            // Posts Tab
            BrokerPostsTab(brokerId: broker.id),
          ],
        ),
      ),
    );
  }
}
