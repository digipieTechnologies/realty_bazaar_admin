import 'package:equatable/equatable.dart';

class ChatRoomParticipantModel extends Equatable {
  final String id;
  final String roomId;
  final String userId;
  final String role;
  final String? lastReadMessageId;
  final DateTime? lastReadAt;
  final DateTime joinedAt;
  final bool isMuted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoomParticipantModel({
    required this.id,
    required this.roomId,
    required this.userId,
    this.role = 'member',
    this.lastReadMessageId,
    this.lastReadAt,
    required this.joinedAt,
    this.isMuted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoomParticipantModel.fromJson(dynamic json) {
    if (json is! Map) {
      return ChatRoomParticipantModel(
        id: '',
        roomId: '',
        userId: '',
        joinedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return ChatRoomParticipantModel(
      id: json['id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'member',
      lastReadMessageId: json['last_read_message_id']?.toString(),
      lastReadAt: json['last_read_at'] != null
          ? DateTime.tryParse(json['last_read_at'].toString())?.toLocal()
          : null,
      joinedAt: json['joined_at'] != null
          ? (DateTime.tryParse(json['joined_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      isMuted: json['is_muted'] == true,
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
      'user_id': userId,
      'role': role,
      'last_read_message_id': lastReadMessageId,
      'last_read_at': lastReadAt?.toUtc().toIso8601String(),
      'joined_at': joinedAt.toUtc().toIso8601String(),
      'is_muted': isMuted,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    roomId,
    userId,
    role,
    lastReadMessageId,
    lastReadAt,
    joinedAt,
    isMuted,
    createdAt,
    updatedAt,
  ];
}
