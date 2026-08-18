// File: lib/widgets/common/cover_image_widget.dart
// Purpose: Widget for displaying and managing cover image uploads.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/attachment_model.dart';
import '../images/cached_image.dart';

class CoverImageWidget extends StatelessWidget {
  final AttachmentModel? coverImage;
  final bool isLoading;
  final double uploadProgress;
  final VoidCallback? onAddOrReplace;
  final VoidCallback? onRemove;
  final double height;
  final bool isReadOnly;
  final String? hintText;

  const CoverImageWidget({
    super.key,
    this.coverImage,
    this.isLoading = false,
    this.isReadOnly = false,
    this.uploadProgress = 0,
    this.onAddOrReplace,
    this.onRemove,
    this.hintText,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image preview or empty state
          if (coverImage?.url != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedImage(
                imageUrl: coverImage!.url!,
                fit: BoxFit.cover,
                placeholderWidget: (ctx) => _buildPlaceholder(colorScheme),
                errorWidget: (ctx) => _buildErrorPlaceholder(colorScheme),
              ),
            )
          else
            _buildPlaceholder(colorScheme),

          // Loading overlay
          if (isLoading)
            Container(
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: uploadProgress > 0 ? uploadProgress : null,
                      color: Colors.white,
                    ),
                    if (uploadProgress > 0) ...[
                      const SizedBox(height: 8),
                      Text('${(uploadProgress * 100).toInt()}%', style: const TextStyle(color: Colors.white)),
                    ],
                  ],
                ),
              ),
            ),

          // Delete button (top right)
          if (!isLoading && !isReadOnly && coverImage?.url != null && onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: _buildActionButton(
                icon: Icons.delete_outline_rounded,
                onTap: onRemove!,
                colorScheme: colorScheme,
                isDestructive: true,
              ),
            ),

          // Tap to add overlay (when no image)
          if (coverImage?.url == null && !isLoading && onAddOrReplace != null && !isReadOnly)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddOrReplace,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        hintText ?? 'users_add_cover_image'.tr(),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Tap to replace overlay (when has image)
          if (coverImage?.url != null && !isLoading && onAddOrReplace != null && !isReadOnly)
            Positioned(
              bottom: 8,
              left: 8,
              child: _buildActionButton(
                icon: Icons.edit_outlined,
                onTap: onAddOrReplace!,
                colorScheme: colorScheme,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Icon(Icons.broken_image_rounded, size: 40, color: colorScheme.onErrorContainer)),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return Material(
      color: isDestructive ? colorScheme.errorContainer : colorScheme.surface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: isDestructive ? colorScheme.error : colorScheme.onSurface),
        ),
      ),
    );
  }
}
