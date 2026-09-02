// File: lib/modules/brokers/screens/broker_detail_screen.dart
// Purpose: Responsive entry controller for Broker Detail screen.

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/context_ext.dart';
import '../../../models/broker_model.dart';
import '../../../providers/brokers/brokers_provider.dart';
import '../../../providers/users/users_provider.dart';
import '../../../widgets/dialogs/broker_delete_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import 'broker_detail_desktop.dart';
import 'broker_detail_mobile.dart';

class BrokerDetailScreen extends StatelessWidget {
  final BrokerModel? broker;
  final String? brokerId;

  const BrokerDetailScreen({super.key, this.broker, this.brokerId});

  @override
  Widget build(BuildContext context) {
    final brokersProv = context.watch<BrokersProvider>();
    final targetBroker = broker ?? brokersProv.brokers.firstWhereOrNull((b) => b.id == brokerId);

    final colorScheme = context.colorScheme;

    if (targetBroker == null) {
      return Scaffold(
        appBar: AppBar(title: Text('brokers_details'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('no_data'.tr()),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.pop(), child: Text('cancel'.tr())),
            ],
          ),
        ),
      );
    }

    Future<void> onDeleteBroker() async {
      final result = await BrokerDeleteDialog.show(
        context: context,
        businessName: targetBroker.businessName ?? 'broker_fallback_name'.tr(),
      );

      if (result != null && result['confirmed'] == true && context.mounted) {
        final hardDelete = result['hardDelete'] as bool;
        final deleteUsers = result['deleteUsers'] as bool;

        if (hardDelete) {
          if (deleteUsers) {
            try {
              final usersRes = await Supabase.instance.client
                  .from('users')
                  .select('id')
                  .eq('broker_id', targetBroker.id!)
                  .eq('is_deleted', false);

              final userIds = (usersRes as List).map((u) => u['id'] as String).toList();
              for (final userId in userIds) {
                await context.read<UsersProvider>().deleteUser(userId, hardDelete: true);
              }
            } catch (e) {
              debugPrint('Failed to delete associated users: $e');
            }
          }

          final success = await brokersProv.deleteBroker(targetBroker.id!, hardDelete: true);
          if (success && context.mounted) {
            AppToast.showSuccess('Broker Deleted', 'Broker and all associated data permanently removed.');
            context.pop();
          }
        } else {
          final success = await brokersProv.deleteBroker(targetBroker.id!, hardDelete: false);
          if (success && context.mounted) {
            AppToast.showSuccess('Broker Deactivated', 'Broker has been deactivated.');
            context.pop();
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: context.isDesktop
          ? BrokerDetailDesktop(broker: targetBroker, brokersProv: brokersProv, onDelete: onDeleteBroker)
          : BrokerDetailMobile(broker: targetBroker, brokersProv: brokersProv, onDelete: onDeleteBroker),
    );
  }
}
