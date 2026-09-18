// File: lib/models/social_lead_model.dart
// Purpose: Data model representing social leads captured from social posts and manual admin/broker entries.

import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'lead_status_enum.dart';
import 'social_post_model.dart';

class SocialLeadModel extends Equatable {
  static String tableName = "social_leads";

  final String? id;
  final String userName;
  final String? notes;
  final String? propertyDetails;
  final String phone;
  final String? phoneCountryCode;
  final String? phoneCountryIso;
  final SocialPostModel? socialPostId;
  final BrokerModel? brokerId;
  final String? rawBrokerId;
  final String? rawSocialPostId;
  final LeadStatus status;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Backward-compatible & convenience getters ─────────────────────────────

  String get contactNumber {
    final code = phoneCountryCode ?? '91';
    final cleanPhone = phone.trim();
    if (cleanPhone.isEmpty) return '';
    return '+$code $cleanPhone';
  }

  String get whatsappNumber => phone;

  SocialPostModel? get socialPost => socialPostId;
  BrokerModel? get broker => brokerId;

  String? get resolvedBrokerId => brokerId?.id ?? rawBrokerId;
  String? get resolvedSocialPostId => socialPostId?.id ?? rawSocialPostId;

  // Legacy field getters for compatibility
  String get leadName => userName;
  String get leadPhone => phone;
  String? get leadEmail => null;
  String? get platform => socialPost?.platform;

  /// Generates a pre-filled WhatsApp click-to-chat URL with inquiry context.
  String buildWhatsappUrl() {
    final cleanPhone = (phoneCountryCode ?? '91') + phone.replaceAll(RegExp(r'\D'), '');
    final property = socialPost?.property;
    final propertyName = (property?.propertyTitle.isNotEmpty == true)
        ? property!.propertyTitle
        : ((propertyDetails?.isNotEmpty == true) ? propertyDetails! : (socialPost?.caption ?? ''));
    final address = property?.address?.fullAddress ?? '';

    final StringBuffer msgBuffer = StringBuffer();
    msgBuffer.writeln('Hello ${userName.isNotEmpty ? userName : 'there'},');
    msgBuffer.writeln('Thanks for connecting with us regarding Realty Bazaar!');

    if (propertyName.isNotEmpty) {
      msgBuffer.writeln('\nHere are the property details:');
      msgBuffer.writeln('📌 Property: $propertyName');
      if (address.isNotEmpty) {
        msgBuffer.writeln('📍 Location: $address');
      }
    } else if (notes != null && notes!.trim().isNotEmpty) {
      msgBuffer.writeln('\nRegarding your inquiry: ${notes!.trim()}');
    }

    msgBuffer.writeln(
      '\nPlease let us know if you have any questions or when you would like to schedule a visit.',
    );

    final encodedText = Uri.encodeComponent(msgBuffer.toString());
    return 'https://wa.me/$cleanPhone?text=$encodedText';
  }

  const SocialLeadModel({
    this.id,
    this.userName = '',
    this.notes,
    this.propertyDetails,
    this.phone = '',
    this.phoneCountryCode = '91',
    this.phoneCountryIso = 'IN',
    this.socialPostId,
    this.brokerId,
    this.rawBrokerId,
    this.rawSocialPostId,
    this.status = LeadStatus.pending,
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  static SocialLeadModel fromJson(dynamic json) {
    if (json is! Map) {
      return SocialLeadModel(id: json?.toString());
    }

    // Parse Broker
    BrokerModel? parsedBroker;
    String? rawBId;
    if (json['broker'] != null && json['broker'] is Map) {
      parsedBroker = BrokerModel.fromJson(json['broker']);
      rawBId = parsedBroker.id;
    } else if (json['broker_id'] != null) {
      if (json['broker_id'] is Map) {
        parsedBroker = BrokerModel.fromJson(json['broker_id']);
        rawBId = parsedBroker.id;
      } else {
        rawBId = json['broker_id']?.toString();
      }
    }

    // Parse Social Post
    SocialPostModel? parsedPost;
    String? rawPId;
    if (json['social_posts'] != null && json['social_posts'] is Map) {
      parsedPost = SocialPostModel.fromJson(json['social_posts']);
      rawPId = parsedPost.id;
    } else if (json['social_post'] != null && json['social_post'] is Map) {
      parsedPost = SocialPostModel.fromJson(json['social_post']);
      rawPId = parsedPost.id;
    } else if (json['social_post_id'] != null) {
      if (json['social_post_id'] is Map) {
        parsedPost = SocialPostModel.fromJson(json['social_post_id']);
        rawPId = parsedPost.id;
      } else {
        rawPId = json['social_post_id']?.toString();
      }
    }

    final rawPhone =
        json['phone']?.toString() ??
        json['lead_phone']?.toString() ??
        json['contact_number']?.toString() ??
        json['whatsapp_number']?.toString() ??
        '';

    final rawName = json['user_name']?.toString() ?? json['lead_name']?.toString() ?? '';

    return SocialLeadModel(
      id: json['id']?.toString(),
      userName: rawName,
      notes: json['notes']?.toString(),
      propertyDetails: json['property_details']?.toString(),
      phone: rawPhone,
      phoneCountryCode: json['phone_country_code']?.toString() ?? '91',
      phoneCountryIso: json['phone_country_iso']?.toString() ?? 'IN',
      socialPostId: parsedPost,
      brokerId: parsedBroker,
      rawBrokerId: rawBId,
      rawSocialPostId: rawPId,
      status: LeadStatus.fromString(json['status']?.toString()),
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    data['user_name'] = userName;
    data['notes'] = notes;
    data['property_details'] = propertyDetails;
    data['phone'] = phone;
    data['phone_country_code'] = phoneCountryCode ?? '91';
    data['phone_country_iso'] = phoneCountryIso ?? 'IN';
    data['social_post_id'] = socialPostId?.id ?? rawSocialPostId;
    data['broker_id'] = brokerId?.id ?? rawBrokerId;
    data['status'] = status.apiValue;
    data['is_deleted'] = isDeleted;
    if (deletedAt != null) {
      data['deleted_at'] = deletedAt?.toUtc().toIso8601String();
    }
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    return data;
  }

  SocialLeadModel copyWith({
    String? id,
    String? userName,
    String? notes,
    String? propertyDetails,
    String? phone,
    String? phoneCountryCode,
    String? phoneCountryIso,
    SocialPostModel? socialPostId,
    BrokerModel? brokerId,
    String? rawBrokerId,
    String? rawSocialPostId,
    LeadStatus? status,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialLeadModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      notes: notes ?? this.notes,
      propertyDetails: propertyDetails ?? this.propertyDetails,
      phone: phone ?? this.phone,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneCountryIso: phoneCountryIso ?? this.phoneCountryIso,
      socialPostId: socialPostId ?? this.socialPostId,
      brokerId: brokerId ?? this.brokerId,
      rawBrokerId: rawBrokerId ?? this.rawBrokerId,
      rawSocialPostId: rawSocialPostId ?? this.rawSocialPostId,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userName,
    notes,
    propertyDetails,
    phone,
    phoneCountryCode,
    phoneCountryIso,
    socialPostId,
    brokerId,
    rawBrokerId,
    rawSocialPostId,
    status,
    isDeleted,
    deletedAt,
    createdAt,
    updatedAt,
  ];
}
