// File: lib/modules/marketing_teams/screens/marketing_teams_mobile.dart
// Purpose: Mobile layout for Marketing Teams management with card list and bottom sheet filters.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:realty_bazaar_admin/app/app_routes.dart';
import 'package:realty_bazaar_admin/app/context_ext.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../core/filters/filter_field.dart';
import '../../../models/models.dart';
import '../../../providers/marketing_teams/marketing_teams_provider.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/enterprise_quick_filters.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../models/marketing_team_filter_model.dart';
import '../widgets/team_edit_dialog.dart';
import '../widgets/team_summary_section.dart';
import 'marketing_teams_screen.dart';

class MarketingTeamsMobile extends StatelessWidget {
  final MarketingTeamsScreenState state;

  const MarketingTeamsMobile({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final teamsProv = state.teamsProv;
    final teamsList = teamsProv.teams;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          TeamEditDialog.show(context, onSave: (team) => state.createTeam(team));
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Section
            TeamSummarySection(
              totalTeams: teamsProv.totalTeams,
              activeTeams: teamsProv.activeTeams,
              totalMembers: teamsProv.totalMembers,
              assignedBrokers: teamsProv.assignedBrokers,
              unassignedBrokers: teamsProv.unassignedBrokers,
            ),
            const SizedBox(height: 12),

            // Search Bar
            AppSearchBar(
              hintText: 'Search teams...',
              onSearch: (query) => state.filterProvider.updateSearch(query),
              isMobile: true,
              onFilter: state.showFilterBottomSheet,
              activeFilterCount: state.filterProvider.activeFiltersCount,
            ),
            const SizedBox(height: 8),

            // Quick Filters
            EnterpriseQuickFilters(
              provider: state.filterProvider,
              fields: MarketingTeamFilterModel.filterDefinition.fields
                  .where((f) => f.type == FilterType.quickFilter)
                  .toList(),
              isMobile: true,
            ),
            const SizedBox(height: 8),

            // Teams Card List
            Expanded(
              child: teamsProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : teamsList.isEmpty
                  ? Center(
                      child: Text(
                        'No marketing teams found',
                        style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: teamsList.length,
                      padding: const EdgeInsets.only(bottom: 80),
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final team = teamsList[index];
                        return _buildTeamCard(context, team, teamsProv);
                      },
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
    );
  }

  Widget _buildTeamCard(BuildContext context, MarketingTeamModel team, MarketingTeamsProvider teamsProv) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: team.isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.diversity_3_rounded,
                  color: team.isActive ? AppColors.primary : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => context.push(AppRoutes.marketingTeamDetailPath(team.id), extra: team),
                      child: Text(
                        team.name,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (team.territory != null && team.territory!.isNotEmpty)
                      Text(
                        team.territory!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Switch(value: team.isActive, onChanged: (val) => state.toggleTeamStatus(team)),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Team Lead
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        team.leadUser != null
                            ? (team.leadUser!.name ?? team.leadUser!.email ?? '')
                            : 'No Lead',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: team.leadUser != null ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Members
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${team.membersCount} reps', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(width: 12),
              // Brokers
              Row(
                children: [
                  const Icon(Icons.business_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${team.brokersCount} brokers',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View'),
                onPressed: () => context.push(AppRoutes.marketingTeamDetailPath(team.id), extra: team),
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text('edit'.tr()),
                onPressed: () {
                  TeamEditDialog.show(context, team: team, onSave: (updated) => state.updateTeam(updated));
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: Text('delete'.tr(), style: const TextStyle(color: Colors.redAccent)),
                onPressed: () => state.confirmAndDeleteTeam(team),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
