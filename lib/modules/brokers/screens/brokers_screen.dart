// File: lib/modules/brokers/screens/brokers_screen.dart
// Purpose: Entrypoint for Super Admin Brokers screen. Owns state and delegates UI layout to BrokersDesktop or BrokersMobile.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/filters/filter_provider.dart';
import '../../../models/models.dart';
import '../../../providers/brokers/brokers_provider.dart';
import '../../../providers/users/users_provider.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/dialogs/broker_delete_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/broker_filter_model.dart';
import 'brokers_desktop.dart';
import 'brokers_mobile.dart';

class BrokersScreen extends StatefulWidget {
  const BrokersScreen({super.key});

  @override
  State<BrokersScreen> createState() => BrokersScreenState();
}

class BrokersScreenState extends State<BrokersScreen> {
  late final FilterProvider<BrokerFilterModel> filterProvider;
  bool showFilterSidebar = false;

  BrokersProvider get brokersProv => context.watch<BrokersProvider>();

  @override
  void initState() {
    super.initState();
    filterProvider = FilterProvider<BrokerFilterModel>(
      definition: BrokerFilterModel.filterDefinition,
      initialFilters: const BrokerFilterModel(),
      onApply: () {
        final active = filterProvider.activeFilters;
        String? selectedPlan = active.plan;
        if (active.enterpriseOnly == true) {
          selectedPlan = 'Enterprise';
        } else if (active.proOnly == true) {
          selectedPlan = 'Pro';
        }

        final resolvedFilter = active.copyWith(plan: selectedPlan, clearPlan: selectedPlan == null);

        context.read<BrokersProvider>().updateFilter(resolvedFilter);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrokersProvider>().fetchBrokers();
    });
  }

  @override
  void dispose() {
    filterProvider.dispose();
    super.dispose();
  }

  void toggleFilterSidebar() {
    setState(() {
      showFilterSidebar = !showFilterSidebar;
    });
  }

  void showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnterpriseFilterPanel(
        provider: filterProvider,
        isSidebar: false,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> confirmAndDeleteBroker(BrokerModel broker) async {
    final result = await BrokerDeleteDialog.show(
      context: context,
      businessName: broker.businessName ?? "this brokerage",
    );

    if (result != null && result['confirmed'] == true && mounted) {
      final hardDelete = result['hardDelete'] as bool;
      final deleteUsers = result['deleteUsers'] as bool;

      if (hardDelete) {
        if (deleteUsers) {
          try {
            final usersRes = await Supabase.instance.client
                .from('users')
                .select('id')
                .eq('broker_id', broker.id!)
                .eq('is_deleted', false);

            final userIds = (usersRes as List).map((u) => u['id'] as String).toList();
            for (final userId in userIds) {
              await context.read<UsersProvider>().deleteUser(userId, hardDelete: true);
            }
          } catch (e) {
            debugPrint('Failed to delete associated users: $e');
          }
        }

        final success = await context.read<BrokersProvider>().deleteBroker(broker.id!, hardDelete: true);
        if (success && mounted) {
          AppToast.showSuccess('Broker Deleted', 'Broker and all associated data permanently removed.');
        }
      } else {
        final success = await context.read<BrokersProvider>().deleteBroker(broker.id!, hardDelete: false);
        if (success && mounted) {
          AppToast.showSuccess('Broker Deactivated', 'Broker has been deactivated.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return BrokersDesktop(state: this);
    }
    return BrokersMobile(state: this);
  }
}
