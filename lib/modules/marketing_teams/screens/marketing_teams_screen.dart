// File: lib/modules/marketing_teams/screens/marketing_teams_screen.dart
// Purpose: Root entrypoint for Super Admin Marketing Teams module. Owns state and responsive layout switching.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/filters/filter_provider.dart';
import '../../../models/models.dart';
import '../../../providers/marketing_teams/marketing_teams_provider.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/toast/app_toast.dart';
import '../models/marketing_team_filter_model.dart';
import '../widgets/team_delete_dialog.dart';
import 'marketing_teams_desktop.dart';
import 'marketing_teams_mobile.dart';

class MarketingTeamsScreen extends StatefulWidget {
  const MarketingTeamsScreen({super.key});

  @override
  State<MarketingTeamsScreen> createState() => MarketingTeamsScreenState();
}

class MarketingTeamsScreenState extends State<MarketingTeamsScreen> {
  late final FilterProvider<MarketingTeamFilterModel> filterProvider;
  bool showFilterSidebar = false;

  MarketingTeamsProvider get teamsProv => context.watch<MarketingTeamsProvider>();

  @override
  void initState() {
    super.initState();
    filterProvider = FilterProvider<MarketingTeamFilterModel>(
      definition: MarketingTeamFilterModel.filterDefinition,
      initialFilters: const MarketingTeamFilterModel(),
      onApply: () {
        context.read<MarketingTeamsProvider>().updateFilter(filterProvider.activeFilters);
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketingTeamsProvider>().fetchTeams();
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

  Future<void> createTeam(MarketingTeamModel team) async {
    final created = await context.read<MarketingTeamsProvider>().createTeam(
          name: team.name,
          territory: team.territory,
          description: team.description,
          isActive: team.isActive,
        );

    if (created != null && mounted) {
      AppToast.showSuccess('Team Created', 'Marketing team "${created.name}" created successfully.');
    }
  }

  Future<void> updateTeam(MarketingTeamModel team) async {
    final success = await context.read<MarketingTeamsProvider>().updateTeam(team);
    if (success && mounted) {
      AppToast.showSuccess('Team Updated', 'Changes saved successfully.');
    }
  }

  Future<void> toggleTeamStatus(MarketingTeamModel team) async {
    final success = await context.read<MarketingTeamsProvider>().toggleTeamStatus(team.id);
    if (success && mounted) {
      AppToast.showSuccess('Status Updated', 'Team status changed.');
    }
  }

  Future<void> confirmAndDeleteTeam(MarketingTeamModel team) async {
    final result = await TeamDeleteDialog.show(context, team: team);
    if (result != null && result['confirmed'] == true && mounted) {
      final String? reassignTeamId = result['reassignTeamId'] as String?;
      final success = await context.read<MarketingTeamsProvider>().deleteTeam(
            teamId: team.id,
            reassignTeamId: reassignTeamId,
          );
      if (success && mounted) {
        AppToast.showSuccess(
          'Team Deleted',
          reassignTeamId != null
              ? 'Team deleted and brokers reassigned.'
              : 'Team deleted and brokers moved to unassigned.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      return MarketingTeamsDesktop(state: this);
    }
    return MarketingTeamsMobile(state: this);
  }
}
