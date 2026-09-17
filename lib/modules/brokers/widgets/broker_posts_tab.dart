// File: lib/modules/brokers/widgets/broker_posts_tab.dart
// Purpose: Tab child widget displaying social posts created by the selected broker using BrokerService.

import 'package:brokerflow_admin/app/app_colors.dart';
import 'package:brokerflow_admin/app/context_ext.dart';
import 'package:brokerflow_admin/models/media_model.dart';
import 'package:brokerflow_admin/models/social_post_model.dart';
import 'package:brokerflow_admin/modules/brokers/services/broker_service.dart';
import 'package:brokerflow_admin/widgets/common/pagination_widget.dart';
import 'package:brokerflow_admin/widgets/common/tab_header.dart';
import 'package:brokerflow_admin/widgets/media/full_screen_media_viewer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BrokerPostsTab extends StatefulWidget {
  final String? brokerId;

  const BrokerPostsTab({super.key, required this.brokerId});

  @override
  State<BrokerPostsTab> createState() => _BrokerPostsTabState();
}

class _BrokerPostsTabState extends State<BrokerPostsTab> with AutomaticKeepAliveClientMixin {
  late Future<List<SocialPostModel>> _postsFuture;
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    final brokerId = widget.brokerId;
    if (brokerId != null && brokerId.isNotEmpty) {
      _postsFuture = BrokerService().getSocialPostsForBroker(brokerId);
    } else {
      _postsFuture = Future.value([]);
    }
  }

  void _handleRefresh() {
    setState(() {
      _currentPage = 1;
      _loadPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = context.colorScheme;
    final brokerId = widget.brokerId;

    if (brokerId == null || brokerId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabHeader(title: 'tab_posts'.tr(), padding: const EdgeInsets.only(bottom: 12)),
          Expanded(
            child: Center(child: Text('no_posts_for_broker'.tr(), style: context.cardSubtitle)),
          ),
        ],
      );
    }

    return FutureBuilder<List<SocialPostModel>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        final allPosts = snapshot.data ?? [];
        final totalCount = allPosts.length;
        final totalPages = (totalCount / _pageSize).ceil().clamp(1, 999);

        // Paginated slice
        final startIndex = (_currentPage - 1) * _pageSize;
        final endIndex = (startIndex + _pageSize).clamp(0, totalCount);
        final paginatedPosts = (startIndex < totalCount)
            ? allPosts.sublist(startIndex, endIndex)
            : <SocialPostModel>[];

        return Padding(
          padding: const EdgeInsets.all(16).copyWith(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabHeader(
                title: 'tab_posts'.tr(),
                count: snapshot.hasData ? totalCount : null,
                padding: const EdgeInsets.only(bottom: 12),
                onRefresh: _handleRefresh,
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '${'common.error'.tr()}: ${snapshot.error}',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      );
                    }

                    if (allPosts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text('no_posts_for_broker'.tr(), style: context.cardSubtitle),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: paginatedPosts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final post = paginatedPosts[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            post.platform ?? 'Instagram',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            (post.status ?? 'published').toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      post.caption != null && post.caption!.isNotEmpty
                                          ? post.caption!
                                          : 'post_caption'.tr(),
                                      style: const TextStyle(fontSize: 14, height: 1.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (post.createdAt != null)
                                          Text(
                                            DateFormat.yMMMd().add_jm().format(post.createdAt!),
                                            style: TextStyle(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                          ),
                                        if (post.medias != null && post.medias!.isNotEmpty)
                                          InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => FullScreenMediaViewer(
                                                    medias: post.medias ?? <MediaModel>[],
                                                    initialIndex: 0,
                                                  ),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.photo_library_outlined,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${post.medias!.length} Media',
                                                    style: TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        PaginationWidget(
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          totalCount: totalCount,
                          onPageChanged: (page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
