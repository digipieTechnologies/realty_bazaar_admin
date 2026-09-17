// File: lib/models/chat_message_model.dart
// Purpose: Type-safe model for chat messages supporting multi-media, soft delete, and reply tracking in brokerflow_admin.

import 'package:equatable/equatable.dart';

import 'chat_enums.dart';
import 'media_model.dart';

class ChatMessageModel extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType; // 'broker', 'marketing', 'admin'
  final String? message;
  final ChatMessageMessageType messageType;
  final List<MediaModel> medias;
  final Map<String, dynamic>? locationData;
  final String? replyMessageId;
  final ChatMessageModel? replyMessage;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    this.message,
    this.messageType = ChatMessageMessageType.text,
    this.medias = const [],
    this.locationData,
    this.replyMessageId,
    this.replyMessage,
    this.isEdited = false,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => senderType == 'admin';
  bool get isBroker => senderType == 'broker';

  factory ChatMessageModel.fromJson(dynamic json) {
    if (json is! Map) {
      return ChatMessageModel(
        id: '',
        roomId: '',
        senderId: '',
        senderType: 'broker',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    List<MediaModel> parsedMedias = [];
    if (json['medias'] != null && json['medias'] is List) {
      for (final item in json['medias']) {
        if (item != null) {
          parsedMedias.add(MediaModel.fromJson(item));
        }
      }
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderType: json['sender_type']?.toString() ?? 'broker',
      message: json['message']?.toString(),
      messageType: ChatMessageMessageType.fromDbValue(json['message_type']?.toString()),
      medias: parsedMedias,
      locationData: json['location_data'] is Map<String, dynamic> ? json['location_data'] : null,
      replyMessageId: json['reply_message_id']?.toString(),
      replyMessage: json['reply_message'] != null ? ChatMessageModel.fromJson(json['reply_message']) : null,
      isEdited: json['is_edited'] == true || json['is_edited']?.toString() == 'true',
      isDeleted: json['is_deleted'] == true || json['is_deleted']?.toString() == 'true',
      deletedAt: json['deleted_at'] != null ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal() : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message': message,
      'message_type': messageType.dbValue,
      'medias': medias.map((e) => e.toJson()).toList(),
      'location_data': locationData,
      'reply_message_id': replyMessageId,
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderType,
    String? message,
    ChatMessageMessageType? messageType,
    List<MediaModel>? medias,
    Map<String, dynamic>? locationData,
    String? replyMessageId,
    ChatMessageModel? replyMessage,
    bool? isEdited,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      medias: medias ?? this.medias,
      locationData: locationData ?? this.locationData,
      replyMessageId: replyMessageId ?? this.replyMessageId,
      replyMessage: replyMessage ?? this.replyMessage,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        roomId,
        senderId,
        senderType,
        message,
        messageType,
        medias,
        locationData,
        replyMessageId,
        replyMessage,
        isEdited,
        isDeleted,
        deletedAt,
        createdAt,
        updatedAt,
      ];
}
