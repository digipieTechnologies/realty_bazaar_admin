// File: lib/models/support_ticket_model.dart
// Purpose: Comprehensive data model for support tickets in brokerflow_admin with broker metadata, joined chat details, and admin management fields.

import 'package:equatable/equatable.dart';

import 'media_model.dart';
import 'support_enums.dart';

class SupportTicketModel extends Equatable {
  final String id;
  final String ticketNumber;
  final int ticketCounter;
  final String brokerId;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String category;
  final String subject;
  final String description;
  final List<MediaModel> attachments;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String priority; // 'low', 'normal', 'high', 'urgent'
  final String? adminNotes;
  final String? assignedTo;
  final String? assignedAdminName;
  final bool reopenRequested;
  final String? reopenReason;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? brokerBusinessName;
  final String? brokerCode;
  final String? chatRoomId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    this.ticketCounter = 0,
    required this.brokerId,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.category,
    required this.subject,
    required this.description,
    this.attachments = const [],
    this.status = 'open',
    this.priority = 'normal',
    this.adminNotes,
    this.assignedTo,
    this.assignedAdminName,
    this.reopenRequested = false,
    this.reopenReason,
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.brokerBusinessName,
    this.brokerCode,
    this.chatRoomId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';
  bool get isReadOnly => isResolved || isClosed;

  SupportCategory get categoryEnum => SupportCategory.fromDbValue(category);
  SupportTicketStatus get statusEnum => SupportTicketStatus.fromDbValue(status);
  SupportTicketPriority get priorityEnum => SupportTicketPriority.fromDbValue(priority);

  factory SupportTicketModel.fromJson(dynamic json) {
    if (json is! Map) {
      return SupportTicketModel(
        id: '',
        ticketNumber: '',
        brokerId: '',
        userId: '',
        fullName: '',
        email: '',
        category: 'general',
        subject: '',
        description: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    List<MediaModel> parsedAttachments = [];
    if (json['attachments'] != null && json['attachments'] is List) {
      for (final item in json['attachments']) {
        if (item != null) {
          parsedAttachments.add(MediaModel.fromJson(item));
        }
      }
    }

    String? brokerName;
    String? bCode;
    if (json['broker'] is Map) {
      brokerName = json['broker']['business_name']?.toString();
      bCode = json['broker']['broker_code']?.toString();
    } else if (json['brokers'] is Map) {
      brokerName = json['brokers']['business_name']?.toString();
      bCode = json['brokers']['broker_code']?.toString();
    } else if (json['broker_id'] is Map) {
      brokerName = json['broker_id']['business_name']?.toString();
      bCode = json['broker_id']['broker_code']?.toString();
    } else {
      brokerName = json['business_name']?.toString();
      bCode = json['broker_code']?.toString();
    }

    String? adminName;
    if (json['assigned_user'] is Map) {
      adminName = json['assigned_user']['name']?.toString() ?? json['assigned_user']['full_name']?.toString();
    } else if (json['assigned_to_user'] is Map) {
      adminName = json['assigned_to_user']['name']?.toString() ?? json['assigned_to_user']['full_name']?.toString();
    } else if (json['assigned_to'] is Map) {
      adminName = json['assigned_to']['name']?.toString() ?? json['assigned_to']['full_name']?.toString();
    }

    String? cRoomId = json['chat_room_id']?.toString();
    if (cRoomId == null && json['chat_rooms'] is List && (json['chat_rooms'] as List).isNotEmpty) {
      cRoomId = json['chat_rooms'][0]['id']?.toString();
    } else if (cRoomId == null && json['chat_room'] is Map) {
      cRoomId = json['chat_room']['id']?.toString();
    }

    return SupportTicketModel(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? '',
      ticketCounter: int.tryParse(json['ticket_counter']?.toString() ?? '0') ?? 0,
      brokerId: json['broker_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      category: json['category']?.toString() ?? 'general',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      attachments: parsedAttachments,
      status: json['status']?.toString() ?? 'open',
      priority: json['priority']?.toString() ?? 'normal',
      adminNotes: json['admin_notes']?.toString(),
      assignedTo: json['assigned_to']?.toString(),
      assignedAdminName: adminName,
      reopenRequested: json['reopen_requested'] == true || json['reopen_requested']?.toString() == 'true',
      reopenReason: json['reopen_reason']?.toString(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())?.toLocal()
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.tryParse(json['closed_at'].toString())?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      brokerBusinessName: brokerName,
      brokerCode: bCode,
      chatRoomId: cRoomId,
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())?.toLocal()
          : null,
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'ticket_counter': ticketCounter,
      'broker_id': brokerId,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'category': category,
      'subject': subject,
      'description': description,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'status': status,
      'priority': priority,
      'admin_notes': adminNotes,
      'assigned_to': assignedTo,
      'reopen_requested': reopenRequested,
      'reopen_reason': reopenReason,
      'resolved_at': resolvedAt?.toUtc().toIso8601String(),
      'closed_at': closedAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  SupportTicketModel copyWith({
    String? id,
    String? ticketNumber,
    int? ticketCounter,
    String? brokerId,
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? category,
    String? subject,
    String? description,
    List<MediaModel>? attachments,
    String? status,
    String? priority,
    String? adminNotes,
    String? assignedTo,
    String? assignedAdminName,
    bool? reopenRequested,
    String? reopenReason,
    DateTime? resolvedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brokerBusinessName,
    String? brokerCode,
    String? chatRoomId,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      ticketCounter: ticketCounter ?? this.ticketCounter,
      brokerId: brokerId ?? this.brokerId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      adminNotes: adminNotes ?? this.adminNotes,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedAdminName: assignedAdminName ?? this.assignedAdminName,
      reopenRequested: reopenRequested ?? this.reopenRequested,
      reopenReason: reopenReason ?? this.reopenReason,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      brokerBusinessName: brokerBusinessName ?? this.brokerBusinessName,
      brokerCode: brokerCode ?? this.brokerCode,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ticketNumber,
        ticketCounter,
        brokerId,
        userId,
        fullName,
        email,
        phone,
        category,
        subject,
        description,
        attachments,
        status,
        priority,
        adminNotes,
        assignedTo,
        assignedAdminName,
        reopenRequested,
        reopenReason,
        resolvedAt,
        closedAt,
        createdAt,
        updatedAt,
        brokerBusinessName,
        brokerCode,
        chatRoomId,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}
