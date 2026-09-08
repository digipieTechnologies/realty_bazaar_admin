// File: lib/modules/brokers/widgets/broker_detail_overview_tab.dart
// Purpose: Mobile Overview Tab child widget for Broker Details screen with AutomaticKeepAliveClientMixin and TabHeader.

import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/broker_model.dart';
import 'package:brokerflow_admin/providers/brokers/brokers_provider.dart';
import 'package:brokerflow_admin/widgets/common/tab_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BrokerDetailOverviewTab extends StatefulWidget {
  final BrokerModel broker;

  const BrokerDetailOverviewTab({super.key, required this.broker});

  @override
  State<BrokerDetailOverviewTab> createState() => _BrokerDetailOverviewTabState();
}

class _BrokerDetailOverviewTabState extends State<BrokerDetailOverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final broker = widget.broker;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabHeader(
            title: 'brokers_business_info'.tr(),
            padding: const EdgeInsets.only(bottom: 12),
            onRefresh: () {
              context.read<BrokersProvider>().refresh();
            },
          ),
          Center(child: broker.avatarImage(context: context, width: 40, height: 40)),
          const SizedBox(height: 12),
          Center(child: Text(broker.businessName ?? '-', style: context.pageTitle)),
          const SizedBox(height: 4),
          Center(child: Text(broker.plan ?? 'Free', style: context.pageSubtitle)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    title: Text('onboarding_status'.tr()),
                    subtitle: Text((broker.onboardingStatus ?? 'pending').toUpperCase()),
                    leading: const Icon(Icons.assignment_outlined),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('status_active'.tr()),
                    subtitle: Text(broker.isActive == true ? 'status_active'.tr() : 'status_inactive'.tr()),
                    leading: const Icon(Icons.info_outline),
                  ),
                  if (broker.addressId != null) ...[
                    const Divider(),
                    ListTile(
                      title: Text('address'.tr()),
                      subtitle: Text(
                        broker.addressId?.fullAddress?.isNotEmpty == true
                            ? broker.addressId!.fullAddress!
                            : '${broker.addressId?.city ?? ''}, ${broker.addressId?.state ?? ''}',
                      ),
                      leading: const Icon(Icons.location_on_outlined),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
