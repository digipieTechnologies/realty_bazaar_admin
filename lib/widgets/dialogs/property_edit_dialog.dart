// File: lib/widgets/dialogs/property_edit_dialog.dart
// Purpose: Dialog for creating/editing properties in Super Admin panel.

import 'package:brokerflow_admin/models/property_enums.dart';
import 'package:brokerflow_admin/models/property_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../buttons/app_button.dart';
import '../common/customized_dropdown.dart';
import '../inputs/app_textfield.dart';
import 'app_dialog.dart';

class PropertyEditDialog extends StatefulWidget {
  final PropertyModel? property;
  final ValueChanged<PropertyModel> onSave;

  const PropertyEditDialog({super.key, this.property, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    PropertyModel? property,
    required ValueChanged<PropertyModel> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PropertyEditDialog(property: property, onSave: onSave),
    );
  }

  @override
  State<PropertyEditDialog> createState() => _PropertyEditDialogState();
}

class _PropertyEditDialogState extends State<PropertyEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _areaController;
  late PropertyType _propertyType;
  late ListingType _listingType;
  late PropertyStatus _propertyStatus;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _titleController = TextEditingController(text: p?.propertyTitle ?? '');
    _descriptionController = TextEditingController(text: p?.propertyDescription ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toString() : '');
    _areaController = TextEditingController(text: p != null ? p.area.toString() : '');
    _propertyType = p?.propertyType ?? PropertyType.apartment;
    _listingType = p?.listingType ?? ListingType.sale;
    _propertyStatus = p?.propertyStatus ?? PropertyStatus.available;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updated = (widget.property ?? const PropertyModel(propertyTitle: '', price: 0, area: 0)).copyWith(
        propertyTitle: _titleController.text.trim(),
        propertyDescription: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        area: double.tryParse(_areaController.text.trim()) ?? 0,
        propertyType: _propertyType,
        listingType: _listingType,
        propertyStatus: _propertyStatus,
      );
      widget.onSave(updated);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.property != null;

    return AppDialog(
      title: isEditing ? 'properties_edit_property'.tr() : 'properties_add_property'.tr(),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'properties_title'.tr(),
                controller: _titleController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'properties_title_req'.tr() : null,
              ),
              AppTextField(
                label: 'price'.tr(),
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'properties_price_req'.tr() : null,
              ),
              AppTextField(
                label: 'properties_area'.tr(),
                controller: _areaController,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'properties_area_req'.tr() : null,
              ),
              CustomizedDropdown<PropertyType>(
                label: 'type'.tr(),
                value: _propertyType,
                enableSearch: false,
                items: PropertyType.values,
                showAllOption: false,
                displayValue: (t) => t.displayName,
                onChanged: (val) {
                  if (val != null) setState(() => _propertyType = val);
                },
              ),
              CustomizedDropdown<ListingType>(
                label: 'properties_listing_type'.tr(),
                value: _listingType,
                enableSearch: false,
                items: ListingType.values,
                showAllOption: false,
                displayValue: (l) => l.displayName,
                onChanged: (val) {
                  if (val != null) setState(() => _listingType = val);
                },
              ),
              CustomizedDropdown<PropertyStatus>(
                label: 'status'.tr(),
                value: _propertyStatus,
                enableSearch: false,
                items: PropertyStatus.values,
                showAllOption: false,
                displayValue: (s) => s.displayName,
                onChanged: (val) {
                  if (val != null) setState(() => _propertyStatus = val);
                },
              ),
              AppTextField(
                label: 'properties_description'.tr(),
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.outline(text: 'cancel'.tr(), onPressed: () => Navigator.of(context).pop()),
        const SizedBox(width: 12),
        AppButton.solid(text: 'save'.tr(), onPressed: _submit),
      ],
    );
  }
}
