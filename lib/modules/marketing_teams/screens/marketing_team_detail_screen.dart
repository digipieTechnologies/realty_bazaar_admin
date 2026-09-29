// File: lib/modules/marketing_teams/screens/marketing_team_detail_screen.dart
// Purpose: Dedicated detail screen for a Marketing Team with Overview, Members, and Assigned Brokers tabs.

import 'package:realty_bazaar_admin/app/app_routes.dart';
import 'package:realty_bazaar_admin/app/context_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_breadcrumbs.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../../brokers/widgets/assign_broker_dialog.dart';
import '../services/marketing_team_service.dart';
import '../widgets/add_team_member_dialog.dart';
import '../widgets/team_delete_dialog.dart';
import '../widgets/team_edit_dialog.dart';

class MarketingTeamDetailScreen extends StatefulWidget {
  final String teamId;
  final MarketingTeamModel? team;

  const MarketingTeamDetailScreen({
    super.key,
    required this.teamId,
    this.team,
  });

  @override
  State<MarketingTeamDetailScreen> createState() => _MarketingTeamDetailScreenState();
}

class _MarketingTeamDetailScreenState extends State<MarketingTeamDetailScreen>
    with SingleTickerProviderStateMixin {
  final MarketingTeamService _service = MarketingTeamService();

  late TabController _tabController;
  MarketingTeamModel? _team;
  bool _isLoadingTeam = true;
  String? _teamError;

  // Members Tab State
  List<TeamMemberModel> _members = [];
  bool _isLoadingMembers = true;

  // Brokers Tab State
  List<BrokerModel> _assignedBrokers = [];
  bool _isLoadingBrokers = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _team = widget.team;
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadTeam(),
      _loadMembers(),
      _loadAssignedBrokers(),
    ]);
  }

  Future<void> _loadTeam() async {
    try {
      final fetched = await _service.fetchTeamById(widget.teamId);
      if (mounted) {
        setState(() {
          _team = fetched ?? _team;
          _isLoadingTeam = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _teamError = e.toString();
          _isLoadingTeam = false;
        });
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      final members = await _service.fetchTeamMembers(widget.teamId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      debugPrint('[MarketingTeamDetailScreen] Error loading team members: $e');
      if (mounted) {
        setState(() => _isLoadingMembers = false);
        AppToast.showError('Error', 'Failed to load team members: $e');
      }
    }
  }

  Future<void> _loadAssignedBrokers() async {
    setState(() => _isLoadingBrokers = true);
    try {
      final brokers = await _service.fetchAssignedBrokers(widget.teamId);
      if (mounted) {
        setState(() {
          _assignedBrokers = brokers;
          _isLoadingBrokers = false;
        });
      }
    } catch (e) {
      debugPrint('[MarketingTeamDetailScreen] Error loading assigned brokers: $e');
      if (mounted) {
        setState(() => _isLoadingBrokers = false);
        AppToast.showError('Error', 'Failed to load assigned brokers: $e');
      }
    }
  }

  Future<void> _handleEditTeam() async {
    if (_team == null) return;
    await TeamEditDialog.show(
      context,
      team: _team,
      onSave: (updated) async {
        try {
          final saved = await _service.updateTeam(updated);
          setState(() => _team = saved);
          AppToast.showSuccess('Team Updated', 'Changes saved successfully.');
          _loadTeam();
        } catch (e) {
          AppToast.showError('Error', e.toString());
        }
      },
    );
  }

  Future<void> _handleDeleteTeam() async {
    if (_team == null) return;
    final result = await TeamDeleteDialog.show(context, team: _team!);
    if (result != null && result['confirmed'] == true && mounted) {
      try {
        final String? reassignTeamId = result['reassignTeamId'] as String?;
        await _service.deleteTeam(teamId: _team!.id, reassignTeamId: reassignTeamId);
        if (mounted) {
          AppToast.showSuccess('Team Deleted', 'Team has been removed.');
          context.go(AppRoutes.marketingTeams);
        }
      } catch (e) {
        AppToast.showError('Delete Failed', e.toString());
      }
    }
  }

  Future<void> _handleAddMember() async {
    if (_team == null) return;
    final added = await AddTeamMemberDialog.show(
      context,
      teamId: _team!.id,
      teamName: _team!.name,
      existingMemberUserIds: _members.map((m) => m.userId).toList(),
    );
    if (added == true) {
      AppToast.showSuccess('Member Added', 'Staff member assigned to team.');
      _loadMembers();
      _loadTeam();
    }
  }

  Future<void> _handleRemoveMember(TeamMemberModel member) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Remove Member',
      message: 'Are you sure you want to remove ${member.user?.name ?? member.user?.email ?? "this member"} from ${_team?.name}?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        await _service.removeMember(teamId: widget.teamId, userId: member.userId);
        AppToast.showSuccess('Member Removed', 'User removed from team roster.');
        _loadMembers();
        _loadTeam();
      } catch (e) {
        AppToast.showError('Error', e.toString());
      }
    }
  }

  Future<void> _handleToggleLead(TeamMemberModel member) async {
    final newLeadStatus = !member.isLead;
    try {
      await _service.setMemberLeadStatus(
        teamId: widget.teamId,
        userId: member.userId,
        isLead: newLeadStatus,
      );
      AppToast.showSuccess(
        'Lead Updated',
        newLeadStatus
            ? '${member.user?.name ?? "User"} is now the Team Lead.'
            : 'Lead designation removed.',
      );
      _loadMembers();
      _loadTeam();
    } catch (e) {
      AppToast.showError('Error', e.toString());
    }
  }

  Future<void> _handleUnassignBroker(BrokerModel broker) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Unassign Broker',
      message: 'Move ${broker.businessName ?? "this broker"} to unassigned backlog?',
      confirmLabel: 'Unassign',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        await _service.assignBrokerToTeam(brokerId: broker.id!, teamId: null);
        AppToast.showSuccess('Broker Unassigned', 'Moved to unassigned pool.');
        _loadAssignedBrokers();
        _loadTeam();
      } catch (e) {
        AppToast.showError('Error', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTeam && _team == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_team == null && _teamError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(_teamError ?? 'Team not found'),
              const SizedBox(height: 16),
              AppButton.outline(
                text: 'Back to Teams',
                onPressed: () => context.go(AppRoutes.marketingTeams),
              ),
            ],
          ),
        ),
      );
    }

    final team = _team!;

    return Scaffold(
      body: Column(
        children: [
          // Breadcrumbs & Top Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go(AppRoutes.marketingTeams),
                  tooltip: 'Back to Teams',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppBreadcrumbs(
                    padding: EdgeInsets.zero,
                    items: [
                      const BreadcrumbItem(label: 'Marketing Teams', route: AppRoutes.marketingTeams),
                      BreadcrumbItem(label: team.name),
                    ],
                  ),
                ),
                AppButton.outline(
                  text: 'Edit Team',
                  iconData: Icons.edit_outlined,
                  height: 36,
                  onPressed: _handleEditTeam,
                ),
                const SizedBox(width: 8),
                AppButton.solid(
                  text: 'Delete Team',
                  iconData: Icons.delete_outline,
                  color: Colors.redAccent,
                  height: 36,
                  onPressed: _handleDeleteTeam,
                ),
              ],
            ),
          ),

          // Team Header Hero Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: team.isActive
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.diversity_3_rounded,
                    color: team.isActive ? AppColors.primary : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            team.name,
                            style: AppTextStyles.heading1.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: team.isActive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              team.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: team.isActive ? AppColors.success : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (team.territory != null && team.territory!.isNotEmpty) ...[
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              team.territory!,
                              style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 16),
                          ],
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Created ${DateFormat.yMMMd().format(team.createdAt)}',
                            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs Bar
          Container(
            color: context.surfaceColor,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                const Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
                Tab(
                  icon: const Icon(Icons.people_alt_outlined),
                  text: 'Team Members (${_members.length})',
                ),
                Tab(
                  icon: const Icon(Icons.business_rounded),
                  text: 'Assigned Brokers (${_assignedBrokers.length})',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, team),
                _buildMembersTab(context, team),
                _buildBrokersTab(context, team),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Overview ────────────────────────────────────────────────────────
  Widget _buildOverviewTab(BuildContext context, MarketingTeamModel team) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              final width = isDesktop ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatTile(context, 'Field Reps', '${_members.length}', Icons.badge_outlined, AppColors.primary, width),
                  _buildStatTile(context, 'Assigned Brokers', '${_assignedBrokers.length}', Icons.business_center_outlined, const Color(0xFF6366F1), width),
                  _buildStatTile(
                    context,
                    'Team Lead',
                    team.leadUser != null ? (team.leadUser!.name ?? 'Assigned') : 'None',
                    Icons.star_outline_rounded,
                    const Color(0xFFD97706),
                    width,
                  ),
                  _buildStatTile(
                    context,
                    'Operational Status',
                    team.isActive ? 'Active' : 'Inactive',
                    Icons.check_circle_outline_rounded,
                    team.isActive ? AppColors.success : Colors.grey,
                    width,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Information Cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Team Metadata
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team Details', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      _buildInfoRow('Team ID', team.id),
                      const SizedBox(height: 12),
                      _buildInfoRow('Name', team.name),
                      const SizedBox(height: 12),
                      _buildInfoRow('Territory', team.territory ?? 'No territory specified'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Description', team.description ?? 'No description provided'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Last Updated', DateFormat.yMMMd().add_jm().format(team.updatedAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Right: Lead User Card
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Team Lead', style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold)),
                          if (team.leadUser != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LEAD',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (team.leadUser != null) ...[
                        Row(
                          children: [
                            team.leadUser!.avatarImage(context: context, width: 44, height: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.leadUser!.name ?? 'Unnamed',
                                    style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    team.leadUser!.email ?? '',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (team.leadUser!.phone != null && team.leadUser!.phone!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Phone', team.leadUser!.phone!),
                        ],
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 36, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'No Team Lead assigned yet.',
                                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                AppButton.outline(
                                  text: 'Assign Lead in Members Tab',
                                  height: 32,
                                  onPressed: () => _tabController.animateTo(1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.body2),
        ),
      ],
    );
  }

  // ── Tab 2: Team Members ───────────────────────────────────────────────────
  Widget _buildMembersTab(BuildContext context, MarketingTeamModel team) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Roster (${_members.length})',
                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
              ),
              AppButton.solid(
                text: 'Add Member',
                iconData: Icons.person_add_outlined,
                height: 38,
                onPressed: _handleAddMember,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingMembers
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('No members assigned to this team.', style: AppTextStyles.body2),
                            const SizedBox(height: 12),
                            AppButton.outline(
                              text: 'Add First Member',
                              onPressed: _handleAddMember,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: AppDataTable(
                          columns: const [
                            AppDataColumn(label: 'Member', flex: 3),
                            AppDataColumn(label: 'Role & Status', flex: 2),
                            AppDataColumn(label: 'Assigned Date', flex: 2),
                            AppDataColumn(label: 'Team Lead', flex: 1.5),
                            AppDataColumn(label: 'Actions', flex: 1),
                          ],
                          rows: _members.map((member) {
                            final user = member.user;
                            return DataRowItem(
                              cells: [
                                Row(
                                  children: [
                                    if (user != null)
                                      user.avatarImage(context: context, width: 34, height: 34)
                                    else
                                      const CircleAvatar(radius: 17, child: Icon(Icons.person, size: 16)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            user?.name ?? 'Unknown User',
                                            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            user?.email ?? '',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user?.role.name.toUpperCase() ?? 'MARKETING',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    DateFormat.yMMMd().format(member.createdAt),
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: InkWell(
                                    onTap: () => _handleToggleLead(member),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            member.isLead ? Icons.star_rounded : Icons.star_border_rounded,
                                            size: 18,
                                            color: member.isLead ? const Color(0xFFD97706) : Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            member.isLead ? 'Lead' : 'Set Lead',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: member.isLead ? FontWeight.bold : FontWeight.normal,
                                              color: member.isLead ? const Color(0xFFD97706) : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    tooltip: 'Remove from team',
                                    onPressed: () => _handleRemoveMember(member),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Assigned Brokers ───────────────────────────────────────────────
  Widget _buildBrokersTab(BuildContext context, MarketingTeamModel team) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned Brokers (${_assignedBrokers.length})',
                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
              ),
              AppButton.outline(
                text: 'Go to Brokers to Assign',
                iconData: Icons.open_in_new_rounded,
                height: 38,
                onPressed: () => context.go(AppRoutes.brokers),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingBrokers
                ? const Center(child: CircularProgressIndicator())
                : _assignedBrokers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.business_center_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('No brokers assigned to this team.', style: AppTextStyles.body2),
                            const SizedBox(height: 12),
                            AppButton.outline(
                              text: 'Assign Brokers',
                              onPressed: () => context.go(AppRoutes.brokers),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: AppDataTable(
                          columns: const [
                            AppDataColumn(label: 'Broker', flex: 3),
                            AppDataColumn(label: 'Subscription', flex: 1.5),
                            AppDataColumn(label: 'Onboarding', flex: 1.5),
                            AppDataColumn(label: 'Primary Rep', flex: 2),
                            AppDataColumn(label: 'Actions', flex: 1.5),
                          ],
                          rows: _assignedBrokers.map((broker) {
                            return DataRowItem(
                              cells: [
                                Row(
                                  children: [
                                    broker.avatarImage(context: context, width: 34, height: 34),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            broker.businessName ?? 'Unnamed Broker',
                                            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            broker.id ?? '',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      broker.plan ?? 'Free',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    (broker.onboardingStatus ?? 'pending').toUpperCase(),
                                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: broker.primaryMarketingUser != null
                                      ? Text(
                                          broker.primaryMarketingUser!.name ?? broker.primaryMarketingUser!.email ?? '',
                                          style: AppTextStyles.body2,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Text(
                                          'Team Pool (No Rep)',
                                          style: AppTextStyles.caption.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                                      tooltip: 'Reassign Broker',
                                      onPressed: () async {
                                        final updated = await AssignBrokerDialog.show(context, broker);
                                        if (updated == true) {
                                          _loadAssignedBrokers();
                                          _loadTeam();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.link_off_rounded, size: 18, color: Colors.orange),
                                      tooltip: 'Unassign Broker',
                                      onPressed: () => _handleUnassignBroker(broker),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
