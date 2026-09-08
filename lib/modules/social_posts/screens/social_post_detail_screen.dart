import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/common_ext.dart';
import '../../../models/models.dart';
import '../../../providers/social_posts/social_posts_provider.dart';
import '../../../widgets/common/cached_image.dart';

class SocialPostDetailScreen extends StatefulWidget {
  final String postId;
  final SocialPostModel? post;

  const SocialPostDetailScreen({super.key, required this.postId, this.post});

  @override
  State<SocialPostDetailScreen> createState() => _SocialPostDetailScreenState();
}

class _SocialPostDetailScreenState extends State<SocialPostDetailScreen> {
  SocialPostModel? _postState;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _postState = widget.post;
    if (_postState == null) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final prov = context.read<SocialPostsProvider>();
      final post = prov.posts.firstWhere((p) => p.id == widget.postId);
      setState(() => _postState = post);
    } catch (e) {
      debugPrint('Error loading social post detail: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final post = _postState;
    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: Text('social_posts_details_title'.tr())),
        body: Center(child: Text('social_post_not_found'.tr())),
      );
    }

    // Custom platform coloring
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

    return Scaffold(
      appBar: AppBar(
        title: Text('social_post_detail_header'.tr()),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Post Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: platformColor.withOpacity(0.1),
                    child: Icon(platformIcon, color: platformColor, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.caption ?? 'social_post_no_caption'.tr(),
                          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              post.platform ?? 'platform'.tr(),
                              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(post.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Media & Property Info
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Media Carousel / List Card
                      _buildInfoCard(
                        title: 'social_post_media_previews'.tr(),
                        icon: Icons.image_rounded,
                        children: [
                          if (post.medias == null || post.medias!.isEmpty) ...[
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.border.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppColors.textSecondary,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text('social_post_no_media'.tr(), style: AppTextStyles.body2),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              height: 160,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: post.medias!.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 160,
                                      child: CachedImage(imageUrl: post.medias![index].url, fit: BoxFit.cover),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Property Details Card
                      _buildInfoCard(
                        title: 'social_post_property_details'.tr(),
                        icon: Icons.apartment_rounded,
                        children: [
                          _buildDetailRow('properties_title'.tr(), post.property?.propertyTitle ?? '-'),
                          _buildDetailRow(
                            'properties_listing_type'.tr(),
                            post.property?.listingType.name.toUpperCase() ?? '-',
                          ),
                          _buildDetailRow('price'.tr(), post.property?.price.formatCurrency ?? '-'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Broker & Metrics Metadata
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Broker Details Card
                      _buildInfoCard(
                        title: 'social_post_broker_details'.tr(),
                        icon: Icons.business_rounded,
                        children: [
                          _buildDetailRow('business_name'.tr(), post.broker?.businessName ?? '-'),
                          _buildDetailRow('plan'.tr(), post.broker?.plan ?? '-'),
                          _buildDetailRow('status'.tr(), post.broker?.onboardingStatus?.toUpperCase() ?? '-'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Metrics & Date Timelines
                      _buildInfoCard(
                        title: 'social_post_metadata_performance'.tr(),
                        icon: Icons.insights_rounded,
                        children: [
                          _buildDetailRow(
                            'published_at'.tr(),
                            post.publishedAt != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(post.publishedAt!)
                                : '-',
                          ),
                          _buildDetailRow(
                            'scheduled_at'.tr(),
                            post.scheduledAt != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(post.scheduledAt!)
                                : '-',
                          ),
                          _buildDetailRow(
                            'created_at'.tr(),
                            post.createdAt != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(post.createdAt!)
                                : '-',
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildDetailRow('social_post_views_count'.tr(), '${post.viewsCount ?? 0}'),
                          _buildDetailRow('social_post_comments_count'.tr(), '${post.commentCount ?? 0}'),
                          _buildDetailRow('social_post_likes_count'.tr(), '${post.likesCount ?? 0}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
