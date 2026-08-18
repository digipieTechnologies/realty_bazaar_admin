// File: lib/models/attachment_model.dart
// Purpose: Data model for file attachments and cover images.

import 'package:equatable/equatable.dart';

class AttachmentModel extends Equatable {
  final int? id;
  final String? url;
  final String? type;
  final String? r2Key;
  final String? entityType;
  final String? entityId;
  final DateTime? createdAt;

  const AttachmentModel({
    this.id,
    this.url,
    this.type,
    this.r2Key,
    this.entityType,
    this.entityId,
    this.createdAt,
  });

  factory AttachmentModel.fromJson(dynamic json) {
    if (json is String) {
      return AttachmentModel(url: json);
    }
    if (json is! Map<String, dynamic>) {
      return const AttachmentModel();
    }
    return AttachmentModel(
      id: json['id'] as int?,
      url: (json['url'] ?? json['file_url']) as String?,
      type: (json['type'] ?? json['file_type']) as String?,
      r2Key: json['r2Key'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (url != null) 'url': url,
    if (type != null) 'type': type,
    if (r2Key != null) 'r2Key': r2Key,
    if (entityType != null) 'entity_type': entityType,
    if (entityId != null) 'entity_id': entityId,
    if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, url, type, r2Key, entityType, entityId, createdAt];
}
