// File: lib/modules/properties/widgets/property_preview_dialog.dart
// Purpose: A standalone dialog for reviewing listing details and managing multi-stage uploads in Admin App.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/localization/property_localizer.dart';
import '../../../core/services/r2_storage_service.dart';
import '../../../models/media_model.dart';
import '../../../models/property_model.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import 'property_amenities_wrap.dart';
import 'property_location_card.dart';
import 'property_preview_media_gallery.dart';
import 'property_preview_specs_grid.dart';

class PropertyPreviewDialog extends StatefulWidget {
  final PropertyModel property;
  final bool isEdit;
  final AdminPropertyProvider propertyProvider;
  final ValueChanged<PropertyModel?> onSuccess;

  const PropertyPreviewDialog({
    super.key,
    required this.property,
    required this.isEdit,
    required this.propertyProvider,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required PropertyModel property,
    required bool isEdit,
    required AdminPropertyProvider propertyProvider,
    required ValueChanged<PropertyModel?> onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PropertyPreviewDialog(
        property: property,
        isEdit: isEdit,
        propertyProvider: propertyProvider,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<PropertyPreviewDialog> createState() => _PropertyPreviewDialogState();
}

class _PropertyPreviewDialogState extends State<PropertyPreviewDialog> {
  String _uploadStatusText = "";
  bool _isPublishing = false;
  bool _showSuccessScreen = false;
  PropertyModel? _savedProperty;

  Future<void> _uploadAndSaveProperty(BuildContext dialogContext) async {
    final isEdit = widget.isEdit;
    final property = widget.property;

    final successTitle = isEdit ? 'Property Updated' : 'Property Published';
    final successDesc = isEdit
        ? 'Property details have been updated successfully.'
        : 'Property has been added to the catalog.';

    try {
      final updatedMedias = <MediaModel>[];
      final totalMedias = property.medias.length;

      for (int i = 0; i < totalMedias; i++) {
        final media = property.medias[i];

        if (media.bytes != null) {
          setState(() {
            _uploadStatusText = "Uploading media ${i + 1} of $totalMedias to R2...";
          });

          final ext = media.type == 'video' ? 'mp4' : 'jpg';
          final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          final path = 'listings/$uniqueName';

          final publicUrl = await R2StorageService.uploadFile(
            filePath: path,
            entityType: 'properties',
            entityId: property.id?.toString() ?? 'new',
            customFileName: uniqueName,
            fileBytes: media.bytes,
            skipDbInsert: true,
          );

          if (publicUrl == null || publicUrl.isEmpty) {
            throw Exception('Failed to upload media ${i + 1} to Cloudflare R2.');
          }

          updatedMedias.add(MediaModel(type: media.type, url: publicUrl));
        } else {
          updatedMedias.add(media);
        }
      }

      setState(() {
        _uploadStatusText = "Saving property to database...";
      });

      final finalProperty = property.copyWith(medias: updatedMedias);

      final savedProperty = await widget.propertyProvider.saveProperty(finalProperty, isEdit: isEdit);

      if (!mounted) return;

      if (savedProperty != null) {
        setState(() {
          _uploadStatusText = "Published successfully!";
          _savedProperty = savedProperty;
          _showSuccessScreen = true;
        });
        AppToast.showSuccess(successDesc);
      } else {
        final err = widget.propertyProvider.error ?? 'Could not save property.';
        AppToast.showError(err);
        setState(() {
          _isPublishing = false;
        });
      }
    } catch (e) {
      debugPrint("Error publishing property: $e");
      if (mounted) {
        AppToast.showError(e.toString());
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  void _onDone() {
    Navigator.of(context).pop();
    widget.onSuccess(_savedProperty);
  }

  @override
  Widget build(BuildContext context) {
    final property = _savedProperty ?? widget.property;

    if (_showSuccessScreen) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: AppColors.surface,
        elevation: 24,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440.0),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 54.0),
                ),
                const SizedBox(height: 20.0),
                Text(
                  widget.isEdit ? 'Property Updated' : 'Property Published',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                Text(
                  widget.isEdit
                      ? 'The property listing was successfully modified.'
                      : 'The property has been added to the system database.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(title: 'property_preview_done'.tr(), onPressed: _onDone),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double priceVal = property.price;
    final formattedPrice =
        '₹ ${priceVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    final categoryLabel = PropertyLocalizer.getLocalizedPropertyType(context, property.propertyType);
    final listingLabel = PropertyLocalizer.getLocalizedListingType(context, property.listingType);
    final constStatusLabel = PropertyLocalizer.getLocalizedConstructionStatus(
      context,
      property.constructionStatus,
    );
    final furnishLabel = PropertyLocalizer.getLocalizedFurnishingStatus(context, property.furnishingStatus);

    return AppDialog(
      title: 'property_preview_review_title'.tr(),
      hasCloseIcon: !_isPublishing,
      actions: [
        if (!_isPublishing)
          AppButton(
            title: 'property_preview_back_to_edit'.tr(),
            isBorderOnly: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        AppButton(
          title: _isPublishing
              ? (_uploadStatusText.isNotEmpty ? _uploadStatusText : 'property_preview_publishing'.tr())
              : (widget.isEdit
                    ? 'property_preview_confirm_update'.tr()
                    : 'property_preview_publish_btn'.tr()),
          isLoading: _isPublishing,
          onPressed: _isPublishing
              ? null
              : () async {
                  setState(() {
                    _isPublishing = true;
                    _uploadStatusText = "property_preview_init_publish".tr();
                  });
                  await _uploadAndSaveProperty(context);
                },
        ),
      ],
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropertyPreviewMediaGallery(medias: property.medias),
            const SizedBox(height: 18.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _buildBadge(context, categoryLabel, AppColors.primary),
                _buildBadge(context, listingLabel, Colors.orange),
                _buildBadge(context, constStatusLabel, Colors.green),
                if (furnishLabel.isNotEmpty) _buildBadge(context, furnishLabel, Colors.teal),
              ],
            ),
            const SizedBox(height: 14.0),
            Text(
              formattedPrice,
              style: AppTextStyles.h2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4.0),
            Text(property.propertyTitle, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
            if (property.propertyDescription != null && property.propertyDescription!.isNotEmpty) ...[
              const SizedBox(height: 10.0),
              Text(
                property.propertyDescription!,
                style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 18.0),
            PropertyPreviewSpecsGrid(property: property),
            const SizedBox(height: 18.0),
            PropertyLocationCard(address: property.address),
            const SizedBox(height: 18.0),
            if (property.amenities.isNotEmpty) ...[
              PropertyAmenitiesWrap(amenities: property.amenities),
              const SizedBox(height: 18.0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withOpacity(0.2), width: 1.0),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 11.0),
      ),
    );
  }
}
