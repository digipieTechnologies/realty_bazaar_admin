import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/context_ext.dart';

class BrokerDeleteDialog extends StatefulWidget {
  final String businessName;

  const BrokerDeleteDialog({super.key, required this.businessName});

  static Future<Map<String, dynamic>?> show({required BuildContext context, required String businessName}) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      builder: (context) => BrokerDeleteDialog(businessName: businessName),
    );
  }

  @override
  State<BrokerDeleteDialog> createState() => _BrokerDeleteDialogState();
}

class _BrokerDeleteDialogState extends State<BrokerDeleteDialog> {
  bool _hardDelete = false; // false = soft delete/deactivate, true = hard delete
  bool _deleteUsers = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text('Delete or Deactivate Brokerage', style: context.dialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select the action you want to perform for ${widget.businessName}:',
              style: context.dialogBody,
            ),
            const SizedBox(height: 16),
            RadioListTile<bool>(
              title: const Text(
                'Deactivate Account (Soft Delete)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Temporarily disable access to the brokerage. Data is preserved and can be reactivated later.',
              ),
              value: false,
              groupValue: _hardDelete,
              onChanged: (val) {
                setState(() {
                  _hardDelete = val ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<bool>(
              title: const Text(
                'Permanently Delete (Hard Delete)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Permanently erase the brokerage profile, properties, leads, video requests, and chat messages. This action is irreversible.',
                style: TextStyle(color: _hardDelete ? colorScheme.error : null),
              ),
              value: true,
              groupValue: _hardDelete,
              onChanged: (val) {
                setState(() {
                  _hardDelete = val ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
              activeColor: colorScheme.error,
            ),
            if (_hardDelete) ...[
              const Divider(height: 32),
              CheckboxListTile(
                title: const Text('Delete all associated user accounts?'),
                subtitle: const Text('If unchecked, user accounts will be unlinked but preserved.'),
                value: _deleteUsers,
                onChanged: (val) {
                  setState(() {
                    _deleteUsers = val ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: colorScheme.error,
              ),
            ],
          ],
        ),
      ),
      backgroundColor: colorScheme.surface,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(null),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop({
            'confirmed': true,
            'hardDelete': _hardDelete,
            'deleteUsers': _hardDelete ? _deleteUsers : false,
          }),
          style: FilledButton.styleFrom(
            backgroundColor: _hardDelete ? colorScheme.error : colorScheme.primary,
            foregroundColor: _hardDelete ? colorScheme.onError : colorScheme.onPrimary,
          ),
          child: Text(_hardDelete ? 'Permanently Delete' : 'Deactivate'),
        ),
      ],
    );
  }
}
