import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/common_ext.dart';
import '../../models/models.dart';
import '../../providers/brokers/brokers_provider.dart';
import '../../providers/properties/admin_property_provider.dart';
import '../buttons/app_button.dart';
import '../common/customized_dropdown.dart';
import '../inputs/app_date_field.dart';
import '../inputs/app_textfield.dart';
import 'app_dialog.dart';

class SocialPostEditDialog extends StatefulWidget {
  final SocialPostModel? post;
  final Function(
    String brokerId,
    String propertyId,
    String platform,
    String caption,
    String status,
    DateTime? scheduledAt,
  )
  onSave;

  const SocialPostEditDialog({super.key, this.post, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    SocialPostModel? post,
    required Function(
      String brokerId,
      String propertyId,
      String platform,
      String caption,
      String status,
      DateTime? scheduledAt,
    )
    onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SocialPostEditDialog(post: post, onSave: onSave),
    );
  }

  @override
  State<SocialPostEditDialog> createState() => _SocialPostEditDialogState();
}

class _SocialPostEditDialogState extends State<SocialPostEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _captionController;

  String? _selectedBrokerId;
  String? _selectedPropertyId;
  late String _platform;
  late String _status;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post?.caption ?? '');
    _platform = widget.post?.platform ?? 'Instagram';
    _status = widget.post?.status ?? 'published';
    _scheduledAt = widget.post?.scheduledAt;
    _selectedBrokerId = widget.post?.brokerId ?? widget.post?.broker?.id;
    _selectedPropertyId = widget.post?.propertyId ?? widget.post?.property?.id;

    // Fetch dependencies in background to populate lists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrokersProvider>().fetchBrokers();
      context.read<AdminPropertyProvider>().fetchProperties();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brokersProv = context.watch<BrokersProvider>();
    final propertiesProv = context.watch<AdminPropertyProvider>();

    return AppDialog(
      title: (widget.post == null ? 'social_posts_create_title' : 'social_posts_edit_title').tr(),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Broker Selection (Enabled only on Creation)
              if (widget.post == null) ...[
                CustomizedDropdown<BrokerModel>(
                  label: 'select_broker'.tr(),
                  value: brokersProv.brokers.firstWhereOrNull((b) => b.id == _selectedBrokerId),
                  items: brokersProv.brokers,
                  displayValue: (b) => b.businessName ?? b.id ?? '',
                  onChanged: (val) => setState(() => _selectedBrokerId = val?.id),
                  validator: (val) => val == null ? 'select_broker_req'.tr() : null,
                ),
                // Property Selection (Enabled only on Creation)
                CustomizedDropdown<PropertyModel>(
                  label: 'select_property'.tr(),
                  value: propertiesProv.properties.firstWhereOrNull((p) => p.id == _selectedPropertyId),
                  items: propertiesProv.properties,
                  displayValue: (p) => p.propertyTitle,
                  onChanged: (val) => setState(() => _selectedPropertyId = val?.id),
                  validator: (val) => val == null ? 'select_property_req'.tr() : null,
                ),
              ] else ...[
                // Disabled / View-Only labels during Editing
                AppTextField(
                  label: 'brokers'.tr(),
                  controller: TextEditingController(text: widget.post?.broker?.businessName ?? '-'),
                  enabled: false,
                ),
                AppTextField(
                  label: 'properties'.tr(),
                  controller: TextEditingController(text: widget.post?.property?.propertyTitle ?? '-'),
                  enabled: false,
                ),
              ],

              // Caption Field
              AppTextField(
                label: 'caption'.tr(),
                controller: _captionController,
                maxLines: 4,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'caption_req'.tr() : null,
              ),

              // Platform Selector
              CustomizedDropdown<String>(
                label: 'platform'.tr(),
                value: _platform,
                items: const ['Instagram', 'Facebook', 'YouTube', 'TikTok'],
                displayValue: (val) => val,
                onChanged: (val) => setState(() => _platform = val ?? 'Instagram'),
              ),

              // Status Selector
              CustomizedDropdown<String>(
                label: 'status'.tr(),
                value: _status,
                items: const ['published', 'scheduled', 'failed'],
                displayValue: (val) => val.sCap(),
                onChanged: (val) => setState(() {
                  _status = val ?? 'published';
                  if (_status != 'scheduled') {
                    _scheduledAt = null;
                  }
                }),
              ),

              // Scheduled Time Picker
              if (_status == 'scheduled') ...[
                AppDateField(
                  label: 'scheduled_at'.tr(),
                  hintText: 'select_date'.tr(),
                  value: _scheduledAt,
                  pickTime: true,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  onChanged: (val) => setState(() => _scheduledAt = val),
                ),
              ],
              const SizedBox(),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 12),
        AppButton.solid(
          text: 'save'.tr(),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_status == 'scheduled' && _scheduledAt == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('scheduled_time_req'.tr())));
                return;
              }
              widget.onSave(
                _selectedBrokerId!,
                _selectedPropertyId!,
                _platform,
                _captionController.text.trim(),
                _status,
                _scheduledAt,
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
