import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class MediaModel extends Equatable {
  final String? type;
  final String? url;
  final String? thumbnail;
  final Uint8List? bytes;
  final Uint8List? thumbnailBytes;

  const MediaModel({this.type, this.url, this.thumbnail, this.bytes, this.thumbnailBytes});

  static MediaModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const MediaModel();
    }
    return MediaModel(
      type: json['type']?.toString(),
      url: json['url']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (type != null) data['type'] = type;
    if (url != null) data['url'] = url;
    if (thumbnail != null) data['thumbnail'] = thumbnail;
    return data;
  }

  MediaModel copyWith({
    String? type,
    String? url,
    String? thumbnail,
    Uint8List? bytes,
    Uint8List? thumbnailBytes,
  }) {
    return MediaModel(
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      bytes: bytes ?? this.bytes,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
    );
  }

  @override
  List<Object?> get props => [type, url, thumbnail, bytes, thumbnailBytes];
}
