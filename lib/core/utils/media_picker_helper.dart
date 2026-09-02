// File: lib/core/utils/media_picker_helper.dart
// Purpose: Centralized utility for picking images/videos via FilePicker, decoding dimensions, and enforcing max limits in Admin App.

import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/media_model.dart';
import '../../widgets/toast/app_toast.dart';

class MediaPickerHelper {
  MediaPickerHelper._();

  /// Decodes raw image bytes to extract exact width, height, and aspect ratio
  static Future<Map<String, double>?> _decodeDimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final width = frameInfo.image.width.toDouble();
      final height = frameInfo.image.height.toDouble();
      frameInfo.image.dispose();
      codec.dispose();
      if (width > 0 && height > 0) {
        return {'width': width, 'height': height, 'aspectRatio': width / height};
      }
    } catch (e) {
      debugPrint('[MediaPickerHelper] Error decoding dimensions: $e');
    }
    return null;
  }

  /// Picks images via FilePicker
  static Future<List<MediaModel>> pickImages({
    required BuildContext context,
    List<MediaModel> currentMedias = const [],
    int maxImages = 6,
  }) async {
    final currentImageCount = currentMedias.where((m) => m.type == 'image').length;
    if (currentImageCount >= maxImages) {
      AppToast.showError('You can upload a maximum of $maxImages property photos.');
      return [];
    }

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return [];

      final allowedCount = maxImages - currentImageCount;
      if (result.files.length > allowedCount) {
        AppToast.showError('Maximum $maxImages photos allowed.');
      }

      final filesToProcess = result.files.take(allowedCount).toList();
      final newMediaList = <MediaModel>[];
      bool duplicateFound = false;

      for (final file in filesToProcess) {
        final pathOrName = file.path ?? file.name;
        final isDuplicate =
            currentMedias.any((m) => m.url == pathOrName) || newMediaList.any((m) => m.url == pathOrName);

        if (isDuplicate) {
          duplicateFound = true;
          continue;
        }

        Uint8List? bytes;
        if (kIsWeb) {
          if (file.bytes == null) continue;
          bytes = file.bytes;
        } else if (file.path != null) {
          bytes = file.bytes ?? await io.File(file.path!).readAsBytes();
        }

        newMediaList.add(
          MediaModel(
            type: 'image',
            url: pathOrName,
            bytes: bytes,
          ),
        );
      }

      if (duplicateFound) {
        AppToast.showError('Some photos were ignored because they are already added.');
      }

      return newMediaList;
    } catch (e) {
      debugPrint('Error picking property images: $e');
      AppToast.showError('Failed to pick photos: $e');
      return [];
    }
  }

  /// Picks videos via FilePicker
  static Future<List<MediaModel>> pickVideos({
    required BuildContext context,
    List<MediaModel> currentMedias = const [],
    int maxVideos = 2,
  }) async {
    final currentVideoCount = currentMedias.where((m) => m.type == 'video').length;
    if (currentVideoCount >= maxVideos) {
      AppToast.showError('You can upload a maximum of $maxVideos property videos.');
      return [];
    }

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return [];

      final allowedCount = maxVideos - currentVideoCount;
      if (result.files.length > allowedCount) {
        AppToast.showError('Maximum $maxVideos videos allowed.');
      }

      final filesToProcess = result.files.take(allowedCount).toList();
      final newMediaList = <MediaModel>[];
      bool duplicateFound = false;

      for (final file in filesToProcess) {
        final pathOrName = file.path ?? file.name;
        final isDuplicate =
            currentMedias.any((m) => m.url == pathOrName) || newMediaList.any((m) => m.url == pathOrName);

        if (isDuplicate) {
          duplicateFound = true;
          continue;
        }

        Uint8List? bytes;
        if (kIsWeb) {
          if (file.bytes == null) continue;
          bytes = file.bytes;
        } else if (file.path != null) {
          bytes = file.bytes ?? await io.File(file.path!).readAsBytes();
        }

        newMediaList.add(
          MediaModel(
            type: 'video',
            url: pathOrName,
            bytes: bytes,
          ),
        );
      }

      if (duplicateFound) {
        AppToast.showError('Some videos were ignored because they are already added.');
      }

      return newMediaList;
    } catch (e) {
      debugPrint('Error picking property videos: $e');
      AppToast.showError('Failed to pick videos: $e');
      return [];
    }
  }
}
