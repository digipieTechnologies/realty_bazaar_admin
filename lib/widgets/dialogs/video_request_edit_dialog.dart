import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/app_text_styles.dart';
import '../../models/models.dart';
import '../buttons/app_button.dart';
import '../common/customized_dropdown.dart';
import '../inputs/app_textfield.dart';
import 'app_dialog.dart';

class VideoRequestEditDialog extends StatefulWidget {
  final VideoRequestModel? request;
  final ValueChanged<VideoRequestModel> onSave;
  final List<BrokerModel> brokers;
  final List<PropertyModel> properties;

  const VideoRequestEditDialog({
    super.key,
    this.request,
    required this.onSave,
    required this.brokers,
    required this.properties,
  });

  static Future<void> show(
    BuildContext context, {
    VideoRequestModel? request,
    required ValueChanged<VideoRequestModel> onSave,
    required List<BrokerModel> brokers,
    required List<PropertyModel> properties,
  }) {
    return showDialog(
      context: context,
      builder: (context) =>
          VideoRequestEditDialog(request: request, onSave: onSave, brokers: brokers, properties: properties),
    );
  }

  @override
  State<VideoRequestEditDialog> createState() => _VideoRequestEditDialogState();
}

class _VideoRequestEditDialogState extends State<VideoRequestEditDialog> {
  late TextEditingController _notesController;
  late TextEditingController _cancelReasonController;
  late TextEditingController _adminCancelReasonController;

  BrokerModel? _selectedBroker;
  PropertyModel? _selectedProperty;
  late VideoRequestStatus _status;
  late VideoRequestApprovalStatus _approvalStatus;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.request?.notes ?? '');
    _cancelReasonController = TextEditingController(text: widget.request?.cancelReason ?? '');
    _adminCancelReasonController = TextEditingController(text: widget.request?.adminCancelReason ?? '');

    _status = widget.request?.status ?? VideoRequestStatus.pending;
    _approvalStatus = widget.request?.adminApprovalStatus ?? VideoRequestApprovalStatus.pending;

    if (widget.request != null) {
      _selectedBroker = widget.request!.broker;
      _selectedProperty = widget.request!.property;
    } else {
      if (widget.brokers.isNotEmpty) _selectedBroker = widget.brokers.first;
      if (widget.properties.isNotEmpty) _selectedProperty = widget.properties.first;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _cancelReasonController.dispose();
    _adminCancelReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.request != null;

    return AppDialog(
      title: (isEdit ? 'video_requests_edit_title' : 'video_requests_create_title').tr(),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEdit) ...[
                CustomizedDropdown<BrokerModel>(
                  label: 'brokers'.tr(),
                  value: _selectedBroker,
                  enableSearch: true,
                  items: widget.brokers,
                  showAllOption: false,
                  displayValue: (b) => b.businessName ?? 'brokers'.tr(),
                  onChanged: (val) => setState(() => _selectedBroker = val),
                ),
                CustomizedDropdown<PropertyModel>(
                  label: 'properties'.tr(),
                  value: _selectedProperty,
                  enableSearch: true,
                  items: widget.properties,
                  showAllOption: false,
                  displayValue: (p) => p.propertyTitle ?? 'properties'.tr(),
                  onChanged: (val) => setState(() => _selectedProperty = val),
                ),
              ] else ...[
                Text(
                  '${'brokers'.tr()}: ${_selectedBroker?.businessName ?? "N/A"}',
                  style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${'properties'.tr()}: ${_selectedProperty?.propertyTitle ?? "N/A"}',
                  style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                ),
              ],

              CustomizedDropdown<VideoRequestStatus>(
                label: 'status'.tr(),
                value: _status,
                enableSearch: false,
                items: VideoRequestStatus.values.where((s) => s != VideoRequestStatus.unknown).toList(),
                showAllOption: false,
                displayValue: (s) => s.displayName,
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),

              CustomizedDropdown<VideoRequestApprovalStatus>(
                label: 'admin_approval_status'.tr(),
                value: _approvalStatus,
                enableSearch: false,
                items: VideoRequestApprovalStatus.values
                    .where((a) => a != VideoRequestApprovalStatus.unknown)
                    .toList(),
                showAllOption: false,
                displayValue: (a) => a.displayName,
                onChanged: (val) {
                  if (val != null) setState(() => _approvalStatus = val);
                },
              ),

              AppTextField(label: 'notes'.tr(), controller: _notesController, maxLines: 3),

              if (_status == VideoRequestStatus.cancelled) ...[
                AppTextField(label: 'cancel_reason'.tr(), controller: _cancelReasonController, maxLines: 2),
                AppTextField(
                  label: 'admin_cancel_reason'.tr(),
                  controller: _adminCancelReasonController,
                  maxLines: 2,
                ),
              ],
              const SizedBox(),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.of(context).pop()),
        const SizedBox(width: 12),
        AppButton.solid(
          text: 'save'.tr(),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              if (_selectedBroker == null || _selectedProperty == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('select_broker_and_property_req'.tr())));
                return;
              }
              final model = (widget.request ?? const VideoRequestModel()).copyWith(
                broker: _selectedBroker,
                property: _selectedProperty,
                status: _status,
                adminApprovalStatus: _approvalStatus,
                notes: _notesController.text.trim(),
                cancelReason: _status == VideoRequestStatus.cancelled
                    ? _cancelReasonController.text.trim()
                    : null,
                adminCancelReason: _status == VideoRequestStatus.cancelled
                    ? _adminCancelReasonController.text.trim()
                    : null,
              );
              widget.onSave(model);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
