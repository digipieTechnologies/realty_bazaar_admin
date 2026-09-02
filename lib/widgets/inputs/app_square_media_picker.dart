// File: lib/widgets/inputs/app_square_media_picker.dart
// Purpose: Reusable square media picker for images and videos with delete, full-screen preview, and readOnly support in Admin App.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_text_styles.dart';
import '../../core/utils/media_picker_helper.dart';
import '../../models/media_model.dart';
import '../common/cached_image.dart';
import '../media/full_screen_media_viewer.dart';

class AppSquareMediaPicker extends StatefulWidget {
  final List<MediaModel> medias;
  final ValueChanged<List<MediaModel>> onMediasChanged;
  final int maxImages;
  final int maxVideos;
  final bool readOnly;

  const AppSquareMediaPicker({
    super.key,
    required this.medias,
    required this.onMediasChanged,
    this.maxImages = 6,
    this.maxVideos = 2,
    this.readOnly = false,
  });

  @override
  State<AppSquareMediaPicker> createState() => _AppSquareMediaPickerState();
}

class _AppSquareMediaPickerState extends State<AppSquareMediaPicker> {
  late List<MediaModel> _medias;

  @override
  void initState() {
    super.initState();
    _medias = List.from(widget.medias);
  }

  @override
  void didUpdateWidget(covariant AppSquareMediaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medias != widget.medias) {
      setState(() {
        _medias = List.from(widget.medias);
      });
    }
  }

  void _removeMedia(int index) {
    if (widget.readOnly) return;
    setState(() {
      _medias.removeAt(index);
    });
    widget.onMediasChanged(_medias);
  }

  void _removeMediaModel(MediaModel media) {
    if (widget.readOnly) return;
    setState(() {
      _medias.remove(media);
    });
    widget.onMediasChanged(_medias);
  }

  Future<void> _pickImages() async {
    if (widget.readOnly) return;
    final imagesCount = _medias.where((m) => m.type == 'image').length;
    final remaining = widget.maxImages - imagesCount;
    if (remaining <= 0) return;

    final picked = await MediaPickerHelper.pickImages(
        context: context,
        currentMedias: _medias,
        maxImages: remaining,
    );
    if (picked.isNotEmpty) {
      setState(() {
        _medias.addAll(picked);
      });
      widget.onMediasChanged(_medias);
    }
  }

  Future<void> _pickVideos() async {
    if (widget.readOnly) return;
    final videosCount = _medias.where((m) => m.type == 'video').length;
    final remaining = widget.maxVideos - videosCount;
    if (remaining <= 0) return;

    final picked = await MediaPickerHelper.pickVideos(
        context: context,
        currentMedias: _medias,
        maxVideos: remaining,
    );
    if (picked.isNotEmpty) {
      setState(() {
        _medias.addAll(picked);
      });
      widget.onMediasChanged(_medias);
    }
  }

  void _openFullScreenViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMediaViewer(
          medias: _medias,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _medias.where((m) => m.type == 'image').toList();
    final videos = _medias.where((m) => m.type == 'video').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos Section
        _buildImageSection(images),
        const SizedBox(height: 24.0),

        // Videos Section
        _buildVideoSection(videos),
      ],
    );
  }

  Widget _buildImageSection(List<MediaModel> images) {
    final isFull = images.length >= widget.maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'media_picker_photos_title'.tr(),
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 15.0,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '${images.length}/${widget.maxImages}',
                style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'media_picker_photos_subtitle'.tr(),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12.0),

        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final media in images)
              _buildMediaSquareItem(
                key: ValueKey('${media.type}_${media.url ?? media.hashCode}'),
                media: media,
                onDelete: () => _removeMediaModel(media),
              ),
            if (!isFull && !widget.readOnly)
              _buildAddSquareButton(label: 'media_picker_add_photo'.tr(), icon: Icons.add_a_photo_rounded, onTap: _pickImages),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoSection(List<MediaModel> videos) {
    final isFull = videos.length >= widget.maxVideos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'media_picker_videos_title'.tr(),
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 15.0,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                '${videos.length}/${widget.maxVideos}',
                style: const TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'media_picker_videos_subtitle'.tr(),
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12.0),

        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final media in videos)
              _buildMediaSquareItem(
                key: ValueKey('${media.type}_${media.url ?? media.hashCode}'),
                media: media,
                isVideo: true,
                onDelete: () => _removeMediaModel(media),
              ),
            if (!isFull && !widget.readOnly)
              _buildAddSquareButton(
                label: 'media_picker_add_video'.tr(),
                icon: Icons.video_call_rounded,
                isSecondary: true,
                onTap: _pickVideos,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddSquareButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final accentColor = isSecondary ? AppColors.secondary : AppColors.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 105.0,
          height: 105.0,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: accentColor.withOpacity(0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: accentColor, size: 22.0),
              ),
              const SizedBox(height: 8.0),
              Text(
                label,
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSquareItem({
    Key? key,
    required MediaModel media,
    bool isVideo = false,
    required VoidCallback onDelete,
  }) {
    final hasImageBytes = media.bytes != null && media.bytes!.isNotEmpty;
    final displayUrl = (isVideo ? (media.thumbnail ?? media.url) : media.url) ?? '';

    return Container(
      key: key,
      width: 105.0,
      height: 105.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        color: AppColors.surface,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                final index = widget.medias.indexOf(media);
                if (index != -1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenMediaViewer(medias: widget.medias, initialIndex: index),
                    ),
                  );
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: isVideo
                            ? Container(
                                color: Colors.black87,
                                child: const Center(
                                  child: Icon(Icons.videocam_rounded, color: Colors.white, size: 36.0),
                                ),
                              )
                            : CachedImage(
                                imageUrl: displayUrl,
                                imageBytes: hasImageBytes ? media.bytes : null,
                                width: 105.0,
                                height: 105.0,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(13.0),
                              ),
                      ),
                      if (isVideo)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(13.0),
                            ),
                            child: const Center(
                              child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36.0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              top: -6.0,
              right: -6.0,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 13.0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
