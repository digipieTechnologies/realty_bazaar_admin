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
  final String? pageId;
  final String? postId;
  final String? caption;
  final String? permalink;
  final List<String>? mediaUrls;
  final int? viewsCount;
  final int? commentCount;
  final int? likesCount;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const SocialPostModel({
    this.id,
    this.brokerId,
    this.propertyId,
    this.property,
    this.broker,
    this.platform,
    this.pageId,
    this.postId,
    this.caption,
    this.permalink,
    this.mediaUrls,
    this.viewsCount,
    this.commentCount,
    this.likesCount,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  static SocialPostModel fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return SocialPostModel(id: json?.toString());
    }

    List<String> parsedMediaUrls = [];
    if (json['media_urls'] != null && json['media_urls'] is List) {
      parsedMediaUrls =
          (json['media_urls'] as List).map((e) => e.toString()).toList();
    }

    return SocialPostModel(
      id: json['id']?.toString(),
      brokerId: json['broker_id'] is Map<String, dynamic>
          ? json['broker_id']['id']?.toString()
          : json['broker_id']?.toString(),
      propertyId: json['property_id'] is Map<String, dynamic>
          ? json['property_id']['id']?.toString()
          : json['property_id']?.toString(),
      property: json['property_id'] != null &&
              json['property_id'] is Map<String, dynamic>
          ? PropertyModel.fromJson(json['property_id'])
          : null,
      broker:
          json['broker_id'] != null && json['broker_id'] is Map<String, dynamic>
              ? BrokerModel.fromJson(json['broker_id'])
              : null,
      platform: json['platform']?.toString(),
      pageId: json['page_id']?.toString(),
      postId: json['post_id']?.toString(),
      caption: json['caption']?.toString(),
      permalink: json['permalink']?.toString(),
      mediaUrls: parsedMediaUrls,
      viewsCount: json['views_count'] != null
          ? int.tryParse(json['views_count'].toString())
          : 0,
      commentCount: json['comment_count'] != null
          ? int.tryParse(json['comment_count'].toString())
          : 0,
      likesCount: json['likes_count'] != null
          ? int.tryParse(json['likes_count'].toString())
          : 0,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal()
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (id != null) data['id'] = id;
    data['broker_id'] = brokerId ?? broker?.id;
    data['property_id'] = propertyId ?? property?.id;
    data['platform'] = platform;
    if (pageId != null) data['page_id'] = pageId;
    if (postId != null) data['post_id'] = postId;
    data['caption'] = caption;
    if (permalink != null) data['permalink'] = permalink;
    data['media_urls'] = mediaUrls ?? [];
    if (publishedAt != null) {
      data['published_at'] = publishedAt?.toUtc().toIso8601String();
    }
    if (createdAt != null) {
      data['created_at'] = createdAt?.toUtc().toIso8601String();
    }
    if (updatedAt != null) {
      data['updated_at'] = updatedAt?.toUtc().toIso8601String();
    }
    data['is_deleted'] = isDeleted;
    if (deletedAt != null) {
      data['deleted_at'] = deletedAt?.toUtc().toIso8601String();
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
    String? pageId,
    String? postId,
    String? caption,
    String? permalink,
    List<String>? mediaUrls,
    int? viewsCount,
    int? commentCount,
    int? likesCount,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return SocialPostModel(
      id: id ?? this.id,
      brokerId: brokerId ?? this.brokerId,
      propertyId: propertyId ?? this.propertyId,
      property: property ?? this.property,
      broker: broker ?? this.broker,
      platform: platform ?? this.platform,
      pageId: pageId ?? this.pageId,
      postId: postId ?? this.postId,
      caption: caption ?? this.caption,
      permalink: permalink ?? this.permalink,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      viewsCount: viewsCount ?? this.viewsCount,
      commentCount: commentCount ?? this.commentCount,
      likesCount: likesCount ?? this.likesCount,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
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
        pageId,
        postId,
        caption,
        permalink,
        mediaUrls,
        viewsCount,
        commentCount,
        likesCount,
        publishedAt,
        createdAt,
        updatedAt,
        isDeleted,
        deletedAt,
      ];
}
