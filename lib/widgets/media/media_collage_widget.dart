// File: lib/widgets/media/media_collage_widget.dart
// Purpose: Reusable media collage grid widget for property preview and detail views in Admin App.

import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../models/media_model.dart';
import '../common/cached_image.dart';

typedef MediaTapCallback = void Function(int index);
typedef OverflowTapCallback = void Function();

class MediaCollageWidget extends StatelessWidget {
  final List<MediaModel> medias;
  final double height;
  final BorderRadius borderRadius;
  final MediaTapCallback? onMediaTap;
  final OverflowTapCallback? onOverflowTap;
  final bool showEmptyState;

  const MediaCollageWidget({
    super.key,
    required this.medias,
    this.height = 240.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.onMediaTap,
    this.onOverflowTap,
    this.showEmptyState = true,
  });

  @override
  Widget build(BuildContext context) {
    if (medias.isEmpty) {
      if (!showEmptyState) return const SizedBox.shrink();
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 48.0, color: AppColors.textSecondary),
            SizedBox(height: 8.0),
            Text(
              'No Media Attached',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final total = medias.length;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobileCompact = constraints.maxWidth < 460;
            return _buildGalleryGrid(context, total, isMobileCompact);
          },
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context, int total, bool isMobileCompact) {
    if (total == 1) {
      return _buildTile(context, 0);
    }

    if (total == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildTile(context, 0)),
          const SizedBox(width: 4.0),
          Expanded(flex: 2, child: _buildTile(context, 1)),
        ],
      );
    }

    if (isMobileCompact) {
      final extraCount = total - 3;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildTile(context, 0)),
          const SizedBox(width: 4.0),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTile(context, 1)),
                const SizedBox(height: 4.0),
                Expanded(child: _buildOverflowTile(context, 2, extraCount)),
              ],
            ),
          ),
        ],
      );
    }

    if (total == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildTile(context, 0)),
          const SizedBox(width: 4.0),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTile(context, 1)),
                const SizedBox(height: 4.0),
                Expanded(child: _buildTile(context, 2)),
              ],
            ),
          ),
        ],
      );
    }

    if (total == 4) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildTile(context, 0)),
          const SizedBox(width: 4.0),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildTile(context, 1)),
                const SizedBox(height: 4.0),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildTile(context, 2)),
                      const SizedBox(width: 4.0),
                      Expanded(child: _buildTile(context, 3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final extraCount = total - 5;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 3, child: _buildTile(context, 0)),
        const SizedBox(width: 4.0),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildTile(context, 1)),
                    const SizedBox(width: 4.0),
                    Expanded(child: _buildTile(context, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 4.0),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildTile(context, 3)),
                    const SizedBox(width: 4.0),
                    Expanded(child: _buildOverflowTile(context, 4, extraCount)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, int index) {
    return _wrapWithTap(context, index, _buildMediaContent(medias[index]));
  }

  Widget _buildOverflowTile(BuildContext context, int index, int extraCount) {
    final hasOverflow = extraCount > 0;

    final child = Stack(
      fit: StackFit.expand,
      children: [
        _buildMediaContent(medias[index]),
        if (hasOverflow)
          Container(
            color: Colors.black.withOpacity(0.55),
            alignment: Alignment.center,
            child: Text(
              '+$extraCount',
              style: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );

    if (hasOverflow && onOverflowTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onOverflowTap, child: child),
      );
    }

    return _wrapWithTap(context, index, child);
  }

  Widget _wrapWithTap(BuildContext context, int index, Widget child) {
    if (onMediaTap == null) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => onMediaTap!(index), child: child),
    );
  }

  Widget _buildMediaContent(MediaModel media) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (media.type == 'video')
          Container(
            color: Colors.black87,
            child: const Center(
              child: Icon(Icons.videocam_rounded, color: Colors.white, size: 36.0),
            ),
          )
        else
          CachedImage(imageUrl: media.url, imageBytes: media.bytes, fit: BoxFit.cover),
        if (media.type == 'video')
          const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40.0)),
      ],
    );
  }
}
