// File: lib/modules/properties/screens/property_detail_screen.dart
// Purpose: Responsive entry controller for Property Detail screen with async backend property fetching.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/context_ext.dart';
import '../../../models/property_model.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import 'property_detail_desktop.dart';
import 'property_detail_mobile.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel? property;
  final String? propertyId;

  const PropertyDetailScreen({super.key, this.property, this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  PropertyModel? _property;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _property = widget.property;
    } else if (widget.propertyId != null && widget.propertyId!.isNotEmpty) {
      _isLoading = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_property == null && widget.propertyId != null && widget.propertyId!.isNotEmpty) {
        _loadProperty(widget.propertyId!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PropertyDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.property != oldWidget.property && widget.property != null) {
      _property = widget.property;
    } else if (widget.propertyId != oldWidget.propertyId &&
        widget.propertyId != null &&
        widget.propertyId!.isNotEmpty &&
        _property == null) {
      _isLoading = true;
      _loadProperty(widget.propertyId!);
    }
  }

  Future<void> _loadProperty(String id) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await context.read<AdminPropertyProvider>().fetchPropertyById(id);
      if (mounted) {
        setState(() {
          _property = fetched;
          _isLoading = false;
          if (fetched == null) {
            _errorMessage = 'no_data'.tr();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('properties_details'.tr())),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final targetProperty = _property;

    if (_errorMessage != null || targetProperty == null) {
      return Scaffold(
        appBar: AppBar(title: Text('properties_details'.tr())),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'no_data'.tr()),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.pop(), child: Text('cancel'.tr())),
            ],
          ),
        ),
      );
    }

    final propertiesProv = context.watch<AdminPropertyProvider>();

    Future<void> onDeleteProperty() async {
      final confirmed = await ConfirmDialog.showResponsive(
        context: context,
        title: 'properties_delete_title'.tr(),
        message: 'properties_delete_confirm'.tr(namedArgs: {'title': targetProperty.propertyTitle}),
        confirmLabel: 'delete'.tr(),
        cancelLabel: 'cancel'.tr(),
        isDestructive: true,
      );
      if (confirmed == true && context.mounted) {
        propertiesProv.deleteProperty(targetProperty.id!);
        AppToast.showSuccess('properties_delete_success'.tr());
        context.pop();
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: context.isDesktop
          ? PropertyDetailDesktop(
              property: targetProperty,
              propertiesProv: propertiesProv,
              onDelete: onDeleteProperty,
            )
          : PropertyDetailMobile(
              property: targetProperty,
              propertiesProv: propertiesProv,
              onDelete: onDeleteProperty,
            ),
    );
  }
}
