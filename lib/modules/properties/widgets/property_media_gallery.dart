// File: lib/modules/properties/widgets/property_media_gallery.dart
// Purpose: GridView gallery widget displaying property images & videos with AutomaticKeepAliveClientMixin, TabHeader and full-screen viewer trigger.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/context_ext.dart';
import '../../../models/media_model.dart';
import '../../../providers/properties/admin_property_provider.dart';
import '../../../widgets/common/cached_image.dart';
import '../../../widgets/common/tab_header.dart';
import '../../../widgets/media/full_screen_media_viewer.dart';

class PropertyMediaGallery extends StatefulWidget {
  final List<MediaModel> medias;

  const PropertyMediaGallery({super.key, required this.medias});

  @override
  State<PropertyMediaGallery> createState() => _PropertyMediaGalleryState();
}

class _PropertyMediaGalleryState extends State<PropertyMediaGallery> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _openMediaViewer(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMediaViewer(medias: widget.medias, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = context.colorScheme;
    final medias = widget.medias;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabHeader(
          title: 'tab_media'.tr(),
          count: medias.length,
          padding: const EdgeInsets.only(bottom: 12),
          onRefresh: () {
            context.read<AdminPropertyProvider>().refresh();
          },
        ),
        Expanded(
          child: medias.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text('no_media_available'.tr(), style: context.cardSubtitle.copyWith(fontSize: 14)),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 4;
                    if (constraints.maxWidth < 450) {
                      crossAxisCount = 2;
                    } else if (constraints.maxWidth < 750) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth < 1100) {
                      crossAxisCount = 4;
                    } else {
                      crossAxisCount = 5;
                    }

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: medias.length,
                      itemBuilder: (context, index) {
                        final media = medias[index];
                        return _MediaGridTile(media: media, onTap: () => _openMediaViewer(context, index));
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MediaGridTile extends StatefulWidget {
  final MediaModel media;
  final VoidCallback onTap;

  const _MediaGridTile({required this.media, required this.onTap});

  @override
  State<_MediaGridTile> createState() => _MediaGridTileState();
}

class _MediaGridTileState extends State<_MediaGridTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isVideo = widget.media.type == 'video';
    final imageUrl = isVideo ? (widget.media.thumbnail ?? widget.media.url) : widget.media.url;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: _isHovered ? (Matrix4.identity()..scale(1.02)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image or Video Thumbnail
                CachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                  backgroundColor: colorScheme.secondaryContainer,
                ),

                // Hover Dark Overlay
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: _isHovered ? Colors.black.withOpacity(0.2) : Colors.transparent,
                ),

                // Video Badge / Play Icon
                if (isVideo)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                    ),
                  ),

                // Video Label Pill in top corner
                if (isVideo)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'VIDEO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
