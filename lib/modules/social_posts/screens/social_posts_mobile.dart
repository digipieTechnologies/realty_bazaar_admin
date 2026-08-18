import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/social_posts/social_posts_provider.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../models/social_post_filter_model.dart';
import 'social_posts_screen.dart';

class SocialPostsMobile extends StatelessWidget {
  final SocialPostsScreenState state;

  const SocialPostsMobile({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final postsProv = state.postsProv;
    final postsList = postsProv.posts;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => state.createOrEditPost(),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
            AppSearchBar(
              hintText: 'Search captions...',
              onSearch: (query) => postsProv.setSearchQuery(query),
              isMobile: true,
              onFilter: state.showFilterBottomSheet,
              activeFilterCount: state.filterProvider.activeFiltersCount,
            ),
            const SizedBox(height: 8),
            EnterpriseQuickFilters(
              provider: state.filterProvider,
              fields: SocialPostFilterModel.filterDefinition.fields
                  .where((f) => f.type == FilterType.quickFilter)
                  .toList(),
              isMobile: true,
            ),

            // Card list with Swipe to Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => postsProv.refresh(),
                child: postsProv.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : postsList.isEmpty
                    ? Center(child: Text('no_data'.tr(), style: AppTextStyles.body2))
                    : ListView.separated(
                        itemCount: postsList.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final post = postsList[index];
                          return _buildPostCard(context, post, postsProv);
                        },
                      ),
              ),
            ),

            PaginationWidget(
              pagination: postsProv.pagination,
              currentPage: postsProv.currentPage,
              totalPages: postsProv.totalPages,
              totalCount: postsProv.totalCount,
              isLoading: postsProv.isLoading,
              onPageChanged: (page) => postsProv.setPage(page),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, SocialPostModel post, SocialPostsProvider postsProv) {
    IconData platformIcon = Icons.article_rounded;
    Color platformColor = AppColors.primary;
    if (post.platform?.toLowerCase() == 'instagram') {
      platformIcon = Icons.camera_alt_outlined;
      platformColor = Colors.pink;
    } else if (post.platform?.toLowerCase() == 'facebook') {
      platformIcon = Icons.facebook_rounded;
      platformColor = Colors.blueAccent;
    } else if (post.platform?.toLowerCase() == 'youtube') {
      platformIcon = Icons.play_circle_fill_rounded;
      platformColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => context.pushNamed(socialPostsDetailPath, pathParameters: {'id': post.id!}, extra: post),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: platformColor.withOpacity(0.1),
                    child: Icon(platformIcon, color: platformColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post.platform ?? 'Platform',
                      style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusBadge(post.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.caption ?? 'No caption',
                style: AppTextStyles.body2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Broker: ${post.broker?.businessName ?? "-"}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Property: ${post.property?.propertyTitle ?? "-"}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppColors.primary,
                        onPressed: () => state.createOrEditPost(post: post),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppColors.error,
                        onPressed: () => state.confirmAndDeletePost(post),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bg = AppColors.successLight;
    Color fg = AppColors.success;
    String label = status ?? 'published';

    if (label == 'scheduled') {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
    } else if (label == 'failed') {
      bg = AppColors.errorLight;
      fg = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.0)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
