// File: lib/modules/marketing_teams/screens/marketing_teams_desktop.dart
// Purpose: Desktop layout for Marketing Teams management with AppDataTable, quick filters, and KPI summary.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realty_bazaar_admin/app/app_routes.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/marketing_teams/marketing_teams_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_filter_panel.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../models/marketing_team_filter_model.dart';
import '../widgets/team_edit_dialog.dart';
import '../widgets/team_summary_section.dart';
import 'marketing_teams_screen.dart';

class MarketingTeamsDesktop extends StatelessWidget {
  final MarketingTeamsScreenState state;

  const MarketingTeamsDesktop({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final teamsProv = state.teamsProv;
    final teamsList = teamsProv.teams;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Summary Cards
          TeamSummarySection(
            totalTeams: teamsProv.totalTeams,
            activeTeams: teamsProv.activeTeams,
            totalMembers: teamsProv.totalMembers,
            assignedBrokers: teamsProv.assignedBrokers,
            unassignedBrokers: teamsProv.unassignedBrokers,
          ),
          const SizedBox(height: 12),

          // Search & Filters Header
          AppSearchBar(
            hintText: 'Search by team name, territory, or description...',
            onSearch: (query) => state.filterProvider.updateSearch(query),
            isMobile: false,
            onFilter: state.toggleFilterSidebar,
            addLabel: 'Add Team',
            activeFilterCount: state.filterProvider.activeFiltersCount,
            onAdd: () {
              TeamEditDialog.show(context, onSave: (team) => state.createTeam(team));
            },
          ),
          const SizedBox(height: 8),

          // Quick Filter Chips
          EnterpriseQuickFilters(
            provider: state.filterProvider,
            fields: MarketingTeamFilterModel.filterDefinition.fields
                .where((f) => f.type == FilterType.quickFilter)
                .toList(),
            isMobile: false,
          ),
          const SizedBox(height: 8),

          // Data Table & Filter Sidebar Row
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: AppDataTable(
                          isLoading: teamsProv.isLoading,
                          columns: const [
                            AppDataColumn(label: 'Team & Territory', flex: 2.5),
                            AppDataColumn(label: 'Team Lead', flex: 2.0),
                            AppDataColumn(label: 'Field Reps', flex: 1.2),
                            AppDataColumn(label: 'Assigned Brokers', flex: 1.5),
                            AppDataColumn(label: 'Active', flex: 1.0),
                            AppDataColumn(label: 'Actions', flex: 1.0),
                          ],
                          rows: teamsList.map((team) => _buildRow(context, team, teamsProv)).toList(),
                        ),
                      ),
                      PaginationWidget(
                        pagination: teamsProv.pagination,
                        currentPage: teamsProv.currentPage,
                        totalPages: teamsProv.totalPages,
                        totalCount: teamsProv.totalCount,
                        isLoading: teamsProv.isLoading,
                        onPageChanged: (page) => teamsProv.setPage(page),
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

  DataRowItem _buildRow(BuildContext context, MarketingTeamModel team, MarketingTeamsProvider teamsProv) {
    return DataRowItem(
      cells: [
        // Column 1: Team Name & Territory
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: team.isActive
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.diversity_3_rounded,
                color: team.isActive ? AppColors.primary : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => context.push(AppRoutes.marketingTeamDetailPath(team.id), extra: team),
                    child: Text(
                      team.name,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (team.territory != null && team.territory!.isNotEmpty) ...[
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            team.territory!,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'No territory set',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Column 2: Team Lead
        Align(
          alignment: Alignment.centerLeft,
          child: team.leadUser != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    team.leadUser!.avatarImage(context: context, width: 28, height: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            team.leadUser!.name ?? team.leadUser!.email ?? '',
                            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LEAD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'No Lead',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
        ),

        // Column 3: Field Reps
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${team.membersCount} rep${team.membersCount == 1 ? '' : 's'}',
                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // Column 4: Assigned Brokers
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: team.brokersCount > 0
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 14,
                  color: team.brokersCount > 0 ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${team.brokersCount} broker${team.brokersCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: team.brokersCount > 0 ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Column 5: Status Switch
        Align(
          alignment: Alignment.centerLeft,
          child: Switch(value: team.isActive, onChanged: (val) => state.toggleTeamStatus(team)),
        ),

        // Column 6: Actions
        DataCellActions(
          onView: () => context.push(AppRoutes.marketingTeamDetailPath(team.id), extra: team),
          onEdit: () {
            TeamEditDialog.show(context, team: team, onSave: (updated) => state.updateTeam(updated));
          },
          onDelete: () => state.confirmAndDeleteTeam(team),
        ),
      ],
    );
  }
}
