import 'package:brokerflow_admin/models/media_model.dart';
import 'package:equatable/equatable.dart';

import 'broker_model.dart';
import 'property_model.dart';

class SocialPostModel extends Equatable {
  static String tableName = "social_posts";

  final String? id;
  final String? brokerId;
  final String? propertyId;
  final PropertyModel? property;
  final BrokerModel? broker;
  final String? platform;
  final String? caption;
  final String? permalink;
  final List<MediaModel>? medias;
  final String? status;
  final int? viewsCount;
  final int? commentCount;
  final int? likesCount;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SocialPostModel({
    this.id,
    this.brokerId,
    this.propertyId,
    this.property,
    this.broker,
    this.platform,
    this.caption,
    this.permalink,
    this.medias,
    this.status,
    this.viewsCount,
    this.commentCount,
    this.likesCount,
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  static SocialPostModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return SocialPostModel(id: json?.toString());
    }

    List<MediaModel> parsedMedias = [];
    if (json['media_urls'] != null && json['media_urls'] is List) {
      parsedMedias = (json['media_urls'] as List).map((e) => MediaModel.fromJson(e)).toList();
    }
    return SocialPostModel(
      id: json['id']?.toString(),
      brokerId: json['broker_id']?.toString(),
      propertyId: json['property_id']?.toString(),
      property: json['property_id'] != null && json['property_id'] is Map<String, dynamic>
          ? PropertyModel.fromJson(json['property_id'])
          : null,
      broker: json['broker_id'] != null && json['broker_id'] is Map<String, dynamic>
          ? BrokerModel.fromJson(json['broker_id'])
          : null,
      platform: json['platform']?.toString() ?? 'Instagram',
      caption: json['caption']?.toString() ?? '',
      permalink: json['permalink']?.toString(),
      medias: parsedMedias,
      status: json['status']?.toString() ?? 'published',
      viewsCount: json['views_count'] != null ? int.tryParse(json['views_count'].toString()) : 0,
      commentCount: json['comment_count'] != null ? int.tryParse(json['comment_count'].toString()) : 0,
      likesCount: json['likes_count'] != null ? int.tryParse(json['likes_count'].toString()) : 0,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())?.toLocal()
          : null,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())?.toLocal()
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
    data['broker_id'] = brokerId ?? broker?.id;
    data['property_id'] = propertyId ?? property?.id;
    data['platform'] = platform;
    data['caption'] = caption;
    if (permalink != null) data['permalink'] = permalink;
    data['media_urls'] = medias;
    data['status'] = status;
    if (scheduledAt != null) {
      data['scheduled_at'] = scheduledAt?.toUtc().toIso8601String();
    }
    if (publishedAt != null) {
      data['published_at'] = publishedAt?.toUtc().toIso8601String();
    }
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    return data;
  }

  SocialPostModel copyWith({
    String? id,
    String? brokerId,
    String? propertyId,
    PropertyModel? property,
    BrokerModel? broker,
    String? platform,
    String? caption,
    String? permalink,
    List<MediaModel>? mediaUrls,
    String? status,
    int? viewsCount,
    int? commentCount,
    int? likesCount,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialPostModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      propertyId: propertyId ?? this.propertyId,
      property: property ?? this.property,
      broker: broker ?? this.broker,
      platform: platform ?? this.platform,
      caption: caption ?? this.caption,
      permalink: permalink ?? this.permalink,
      medias: mediaUrls ?? this.medias,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      commentCount: commentCount ?? this.commentCount,
      likesCount: likesCount ?? this.likesCount,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    brokerId,
    propertyId,
    property,
    broker,
    platform,
    caption,
    permalink,
    medias,
    status,
    viewsCount,
    commentCount,
    likesCount,
    scheduledAt,
    publishedAt,
    createdAt,
    updatedAt,
  ];
}
