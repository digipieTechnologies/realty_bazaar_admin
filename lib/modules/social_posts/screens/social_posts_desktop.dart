import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/social_posts/social_posts_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../models/social_post_filter_model.dart';
import 'social_posts_screen.dart';

class SocialPostsDesktop extends StatelessWidget {
  final SocialPostsScreenState state;

  const SocialPostsDesktop({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final postsProv = state.postsProv;
    final postsList = postsProv.posts;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters and Search Bar
          AppSearchBar(
            hintText: 'Search captions...',
            onSearch: (query) => postsProv.setSearchQuery(query),
            isMobile: false,
            onFilter: state.toggleFilterSidebar,
            activeFilterCount: state.filterProvider.activeFiltersCount,
          ),
          const SizedBox(height: 8),
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: SocialPostFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: false,
          ),

          // Data Table & Sidebar Filter
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: AppDataTable(
                          isLoading: postsProv.isLoading,
                          columns: [
                            const AppDataColumn(label: 'Post Details', flex: 3),
                            const AppDataColumn(label: 'Platform', flex: 1.2),
                            const AppDataColumn(label: 'Broker', flex: 1.5),
                            const AppDataColumn(label: 'Property', flex: 1.5),
                            const AppDataColumn(label: 'Status', flex: 1.2),
                            const AppDataColumn(label: 'Actions', flex: 1),
                          ],
                          rows: postsList.map((post) => _buildRow(context, post, postsProv)).toList(),
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
                if (state.showFilterSidebar) ...[
                  const SizedBox(width: 16),
                  EnterpriseFilterPanel(
                    provider: state.filterProvider,
                    isSidebar: true,
                    onClose: state.toggleFilterSidebar,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRowItem _buildRow(BuildContext context, SocialPostModel post, SocialPostsProvider postsProv) {
    // Custom platform icons
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

    return DataRowItem(
      cells: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: platformColor.withOpacity(0.1),
                child: Icon(platformIcon, color: platformColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.caption ?? '-',
                      style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.publishedAt != null
                          ? 'Published: ${DateFormat('dd MMM yyyy').format(post.publishedAt!)}'
                          : post.scheduledAt != null
                          ? 'Scheduled: ${DateFormat('dd MMM yyyy, hh:mm a').format(post.scheduledAt!)}'
                          : 'Drafted',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCellText(text: post.platform ?? '-'),
        DataCellText(text: post.broker?.businessName ?? '-'),
        DataCellText(text: post.property?.propertyTitle ?? '-'),
        Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(post.status)),
        DataCellActions(
          onView: () =>
              context.pushNamed(socialPostsDetailPath, pathParameters: {'id': post.id!}, extra: post),
          onEdit: () => state.createOrEditPost(post: post),
          onDelete: () => state.confirmAndDeletePost(post),
        ),
      ],
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
