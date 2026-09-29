// File: lib/modules/marketing_teams/widgets/team_summary_section.dart
// Purpose: Collapsible KPI summary header showing key team metrics and broker assignment distribution.

import 'package:realty_bazaar_admin/app/context_ext.dart';
import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';

class TeamSummarySection extends StatefulWidget {
  final int totalTeams;
  final int activeTeams;
  final int totalMembers;
  final int assignedBrokers;
  final int unassignedBrokers;

  const TeamSummarySection({
    super.key,
    required this.totalTeams,
    required this.activeTeams,
    required this.totalMembers,
    required this.assignedBrokers,
    required this.unassignedBrokers,
  });

  @override
  State<TeamSummarySection> createState() => _TeamSummarySectionState();
}

class _TeamSummarySectionState extends State<TeamSummarySection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final totalBrokers = widget.assignedBrokers + widget.unassignedBrokers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Overview & Metrics',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final cardWidth = isDesktop
                  ? (constraints.maxWidth - (3 * 12)) / 4
                  : (constraints.maxWidth > 550
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth);

              return Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  _buildCard(
                    context,
                    title: 'Total Teams',
                    value: widget.totalTeams.toString(),
                    subtitle: 'Configured units',
                    icon: Icons.diversity_3_rounded,
                    color: AppColors.primary,
                    width: cardWidth,
                  ),
                  _buildCard(
                    context,
                    title: 'Active Teams',
                    value: widget.activeTeams.toString(),
                    subtitle: '${((widget.activeTeams / (widget.totalTeams == 0 ? 1 : widget.totalTeams)) * 100).round()}% operational',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    width: cardWidth,
                  ),
                  _buildCard(
                    context,
                    title: 'Field Reps',
                    value: widget.totalMembers.toString(),
                    subtitle: 'Assigned staff',
                    icon: Icons.badge_outlined,
                    color: const Color(0xFF6366F1), // Indigo
                    width: cardWidth,
                  ),
                  _buildCard(
                    context,
                    title: 'Assigned Brokers',
                    value: '${widget.assignedBrokers} / $totalBrokers',
                    subtitle: '${widget.unassignedBrokers} unassigned',
                    icon: Icons.business_center_outlined,
                    color: widget.unassignedBrokers > 0 ? AppColors.warning : AppColors.success,
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: context.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 20.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  value,
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.0,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
