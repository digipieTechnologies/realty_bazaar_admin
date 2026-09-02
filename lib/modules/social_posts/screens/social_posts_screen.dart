import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/context_ext.dart';
import '../../../core/filters/filter_provider.dart';
import '../../../models/models.dart';
import '../../../providers/social_posts/social_posts_provider.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/dialogs/social_post_edit_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/social_post_filter_model.dart';
import 'social_posts_desktop.dart';
import 'social_posts_mobile.dart';

class SocialPostsScreen extends StatefulWidget {
  const SocialPostsScreen({super.key});

  @override
  State<SocialPostsScreen> createState() => SocialPostsScreenState();
}

class SocialPostsScreenState extends State<SocialPostsScreen> {
  late final FilterProvider<SocialPostFilterModel> filterProvider;
  bool showFilterSidebar = false;

  SocialPostsProvider get postsProv => context.watch<SocialPostsProvider>();

  @override
  void initState() {
    super.initState();
    filterProvider = FilterProvider<SocialPostFilterModel>(
      definition: SocialPostFilterModel.filterDefinition,
      initialFilters: const SocialPostFilterModel(),
      onApply: () {
        final active = filterProvider.activeFilters;
        context.read<SocialPostsProvider>().updateFilter(active);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialPostsProvider>().fetchSocialPosts();
    });
  }

  @override
  void dispose() {
    filterProvider.dispose();
    super.dispose();
  }

  void toggleFilterSidebar() {
    setState(() {
      showFilterSidebar = !showFilterSidebar;
    });
  }

  void showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EnterpriseFilterPanel(
        provider: filterProvider,
        isSidebar: false,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> confirmAndDeletePost(SocialPostModel post) async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'social_posts_delete_dialog_title'.tr(),
      message: 'social_posts_delete_dialog_msg'.tr(),
      confirmLabel: 'delete'.tr(),
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      final success = await context.read<SocialPostsProvider>().deleteSocialPost(post.id!);
      if (success && mounted) {
        AppToast.showSuccess('social_posts_toast_deleted_title'.tr(), 'social_posts_toast_deleted_msg'.tr());
      }
    }
  }

  Future<void> createOrEditPost({SocialPostModel? post}) async {
    await SocialPostEditDialog.show(
      context,
      post: post,
      onSave: (brokerId, propertyId, platform, caption, status, scheduledAt) async {
        if (post == null) {
          final id = await context.read<SocialPostsProvider>().createSocialPost(
            brokerId: brokerId,
            propertyId: propertyId,
            platform: platform,
            caption: caption,
            status: status,
            scheduledAt: scheduledAt,
          );
          if (id != null && mounted) {
            AppToast.showSuccess('Post Created', 'New social post has been created successfully.');
          }
        } else {
          final updated = post.copyWith(
            caption: caption,
            platform: platform,
            status: status,
            scheduledAt: scheduledAt,
          );
          final success = await context.read<SocialPostsProvider>().updateSocialPost(updated);
          if (success && mounted) {
            AppToast.showSuccess('Post Updated', 'Social post details updated successfully.');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return SocialPostsDesktop(state: this);
    }
    return SocialPostsMobile(state: this);
  }
}
