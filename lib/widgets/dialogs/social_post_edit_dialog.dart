import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/brokers/brokers_provider.dart';
import '../../providers/properties/admin_property_provider.dart';
import '../buttons/app_button.dart';
import '../common/customized_dropdown.dart';
import '../inputs/app_textfield.dart';
import 'app_dialog.dart';

class SocialPostEditDialog extends StatefulWidget {
  final SocialPostModel? post;
  final Function(
    String brokerId,
    String propertyId,
    String platform,
    String caption,
  ) onSave;

  const SocialPostEditDialog({super.key, this.post, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    SocialPostModel? post,
    required Function(
      String brokerId,
      String propertyId,
      String platform,
      String caption,
    ) onSave,
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

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post?.caption ?? '');
    _platform = widget.post?.platform ?? 'Instagram';
    _selectedBrokerId = widget.post?.brokerId ?? widget.post?.broker?.id;
    _selectedPropertyId = widget.post?.propertyId ?? widget.post?.property?.id;

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
              if (widget.post == null) ...[
                CustomizedDropdown<BrokerModel>(
                  label: 'select_broker'.tr(),
                  value: brokersProv.brokers.firstWhereOrNull((b) => b.id == _selectedBrokerId),
                  items: brokersProv.brokers,
                  displayValue: (b) => b.businessName ?? b.id ?? '',
                  onChanged: (val) => setState(() => _selectedBrokerId = val?.id),
                  validator: (val) => val == null ? 'select_broker_req'.tr() : null,
                ),
                CustomizedDropdown<PropertyModel>(
                  label: 'select_property'.tr(),
                  value: propertiesProv.properties.firstWhereOrNull((p) => p.id == _selectedPropertyId),
                  items: propertiesProv.properties,
                  displayValue: (p) => p.propertyTitle,
                  onChanged: (val) => setState(() => _selectedPropertyId = val?.id),
                  validator: (val) => val == null ? 'select_property_req'.tr() : null,
                ),
              ] else ...[
                AppTextField(
                  label: 'brokers'.tr(),
                  controller: TextEditingController(text: widget.post?.broker?.businessName ?? '-'),
                  enabled: false,
                ),
                AppTextField(
                  label: 'properties'.tr(),
                  controller: TextEditingController(
                      text: widget.post?.property?.propertyTitle ?? '-'),
                  enabled: false,
                ),
              ],
              AppTextField(
                label: 'caption'.tr(),
                controller: _captionController,
                maxLines: 4,
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'caption_req'.tr() : null,
              ),
              CustomizedDropdown<String>(
                label: 'platform'.tr(),
                value: _platform,
                items: const ['Instagram', 'Facebook', 'YouTube', 'TikTok'],
                displayValue: (val) => val,
                onChanged: (val) => setState(() => _platform = val ?? 'Instagram'),
              ),
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
              widget.onSave(
                _selectedBrokerId!,
                _selectedPropertyId!,
                _platform,
                _captionController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
