import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/filters/filter_provider.dart';
import '../../../models/models.dart';
import '../../../providers/video_requests/video_requests_provider.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/dialogs/app_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/video_request_filter_model.dart';
import 'video_requests_desktop.dart';
import 'video_requests_mobile.dart';

class VideoRequestsScreen extends StatefulWidget {
  const VideoRequestsScreen({super.key});

  @override
  State<VideoRequestsScreen> createState() => VideoRequestsScreenState();
}

class VideoRequestsScreenState extends State<VideoRequestsScreen> {
  late final FilterProvider<VideoRequestFilterModel> filterProvider;
  bool showFilterSidebar = false;

  VideoRequestsProvider get videoRequestsProv => context.watch<VideoRequestsProvider>();

  @override
  void initState() {
    super.initState();
    filterProvider = FilterProvider<VideoRequestFilterModel>(
      definition: VideoRequestFilterModel.filterDefinition,
      initialFilters: const VideoRequestFilterModel(),
      onApply: () {
        final active = filterProvider.activeFilters;
        context.read<VideoRequestsProvider>().updateFilter(active);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoRequestsProvider>().fetchVideoRequests();
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

  Future<void> confirmAndDeleteRequest(VideoRequestModel request) async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: 'Delete Video Request',
      message: 'Are you sure you want to delete this video request? This will permanently remove the record.',
      confirmLabel: 'Delete Request',
      isDanger: true,
    );
    if (confirmed == true && mounted) {
      final success = await context.read<VideoRequestsProvider>().deleteVideoRequest(request.id!);
      if (success && mounted) {
        AppToast.showSuccess('Request Removed', 'Video request has been deleted.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return VideoRequestsDesktop(state: this);
    }
    return VideoRequestsMobile(state: this);
  }
}
