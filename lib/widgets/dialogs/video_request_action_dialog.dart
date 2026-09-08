import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../buttons/app_button.dart';
import '../inputs/app_textfield.dart';
import 'app_dialog.dart';

class VideoRequestActionDialog extends StatefulWidget {
  final bool isApproval;
  final ValueChanged<String> onSubmit;

  const VideoRequestActionDialog({super.key, required this.isApproval, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required bool isApproval,
    required ValueChanged<String> onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (context) => VideoRequestActionDialog(isApproval: isApproval, onSubmit: onSubmit),
    );
  }

  @override
  State<VideoRequestActionDialog> createState() => _VideoRequestActionDialogState();
}

class _VideoRequestActionDialogState extends State<VideoRequestActionDialog> {
  late TextEditingController _reasonController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isApproval ? 'accept_request'.tr() : 'reject_request'.tr();
    final hintText = widget.isApproval ? 'notes'.tr() : 'admin_cancel_reason'.tr();

    return AppDialog(
      title: titleText,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isApproval
                    ? 'Confirm approval of this video request. You may optionally enter notes below.'
                    : 'Confirm rejection of this video request. You must enter a reason below.',
                style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
              ),
              AppTextField(
                label: hintText,
                controller: _reasonController,
                maxLines: 4,
                validator: (val) {
                  if (!widget.isApproval && (val == null || val.trim().isEmpty)) {
                    return 'enter_reason'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.of(context).pop()),
        const SizedBox(width: 12),
        AppButton.solid(
          text: widget.isApproval ? 'Approve' : 'Reject',
          color: widget.isApproval ? AppColors.primary : AppColors.error,
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onSubmit(_reasonController.text.trim());
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
