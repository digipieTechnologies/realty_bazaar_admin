// File: lib/modules/users/screens/user_detail_screen.dart
// Purpose: Responsive entry controller for User Detail screen.

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/context_ext.dart';
import '../../../models/user_model.dart';
import '../../../providers/users/users_provider.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import 'user_detail_desktop.dart';
import 'user_detail_mobile.dart';

class UserDetailScreen extends StatelessWidget {
  final UserModel? user;
  final String? userId;

  const UserDetailScreen({super.key, this.user, this.userId});

  @override
  Widget build(BuildContext context) {
    final usersProv = context.watch<UsersProvider>();
    final targetUser = user ?? usersProv.users.firstWhereOrNull((u) => u.id == userId);

    final colorScheme = context.colorScheme;

    if (targetUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('users_details'.tr())),
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

    Future<void> onDeleteUser() async {
      final confirmed = await ConfirmDialog.showResponsive(
        context: context,
        title: 'users_delete_title'.tr(),
        message: 'users_delete_confirm'.tr(namedArgs: {'name': targetUser.name ?? ''}),
        confirmLabel: 'delete'.tr(),
        cancelLabel: 'cancel'.tr(),
        isDestructive: true,
      );
      if (confirmed == true && context.mounted) {
        usersProv.deleteUser(targetUser.id!);
        AppToast.showSuccess('users_delete_success'.tr());
        context.pop();
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: context.isDesktop
          ? UserDetailDesktop(user: targetUser, usersProv: usersProv, onDelete: onDeleteUser)
          : UserDetailMobile(user: targetUser, usersProv: usersProv, onDelete: onDeleteUser),
    );
  }
}
