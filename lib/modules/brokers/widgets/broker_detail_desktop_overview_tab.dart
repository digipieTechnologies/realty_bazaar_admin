// File: lib/modules/brokers/widgets/broker_detail_desktop_overview_tab.dart
// Purpose: Desktop Overview Tab child widget for Broker Details screen with AutomaticKeepAliveClientMixin and TabHeader.

import 'package:brokerflow_admin/models/broker_model.dart';
import 'package:brokerflow_admin/providers/brokers/brokers_provider.dart';
import 'package:brokerflow_admin/widgets/common/tab_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BrokerDetailDesktopOverviewTab extends StatefulWidget {
  final BrokerModel broker;

  const BrokerDetailDesktopOverviewTab({super.key, required this.broker});

  @override
  State<BrokerDetailDesktopOverviewTab> createState() => _BrokerDetailDesktopOverviewTabState();
}

class _BrokerDetailDesktopOverviewTabState extends State<BrokerDetailDesktopOverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final broker = widget.broker;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16).copyWith(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabHeader(
            title: 'brokers_business_info'.tr(),
            padding: const EdgeInsets.only(bottom: 16),
            onRefresh: () {
              context.read<BrokersProvider>().refresh();
            },
          ),
          ListTile(
            title: Text('business_name'.tr()),
            subtitle: Text(broker.businessName ?? '-'),
            leading: const Icon(Icons.business_rounded),
          ),
          const Divider(),
          ListTile(
            title: Text('plan'.tr()),
            subtitle: Text(broker.plan ?? 'Free'),
            leading: const Icon(Icons.workspace_premium_outlined),
          ),
          const Divider(),
          ListTile(
            title: Text('onboarding_status'.tr()),
            subtitle: Text((broker.onboardingStatus ?? 'pending').toUpperCase()),
            leading: const Icon(Icons.assignment_turned_in_outlined),
          ),
        ],
      ),
    );
  }
}
