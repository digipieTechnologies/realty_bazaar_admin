// File: lib/modules/support/screens/admin_support_desktop.dart
// Purpose: Super Admin desktop view for support tickets featuring KPI metric cards, enterprise filtering, AppDataTable, and quick action dialogs.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../providers/support/admin_support_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../chat/dialogs/admin_chat_dialog.dart';
import '../widgets/admin_create_ticket_dialog.dart';
import '../widgets/admin_ticket_detail_dialog.dart';

class AdminSupportDesktop extends StatelessWidget {
  const AdminSupportDesktop({super.key});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminSupportProvider>();
    final tickets = provider.tickets;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Summary Cards ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'total_tickets'.tr(),
                  count: provider.totalTicketsCount,
                  icon: Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                  bgColor: AppColors.primary50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'open_tickets'.tr(),
                  count: provider.openCount,
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.info,
                  bgColor: AppColors.infoLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'in_progress_tickets'.tr(),
                  count: provider.inProgressCount,
                  icon: Icons.autorenew_rounded,
                  color: AppColors.warning,
                  bgColor: AppColors.warningLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'reopen_requested'.tr(),
                  count: provider.reopenRequestedCount,
                  icon: Icons.notification_important_rounded,
                  color: AppColors.error,
                  bgColor: AppColors.errorLight,
                  isAlert: provider.reopenRequestedCount > 0,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'resolved_tickets'.tr(),
                  count: provider.resolvedCount,
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.successLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Search & Actions Bar ──────────────────────────────────────
          AppSearchBar(
            hintText: 'search_tickets_hint'.tr(),
            onSearch: (q) => provider.setSearchQuery(q),
            isMobile: false,
            addLabel: 'create_ticket'.tr(),
            onAdd: () => AdminCreateTicketDialog.show(context),
          ),
          const SizedBox(height: 16),

          // ── Quick Filter Tabs & Dropdowns ─────────────────────────────
          Row(
            children: [
              // Status tabs
              _buildFilterChip(
                label: 'common.all'.tr(),
                isSelected: provider.selectedStatusFilter == 'all',
                onSelected: () => provider.setStatusFilter('all'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Unread',
                isSelected: provider.selectedStatusFilter == 'unread',
                countBadge: provider.unreadTicketsCount > 0 ? provider.unreadTicketsCount : null,
                badgeColor: Colors.red.shade600,
                onSelected: () => provider.setStatusFilter('unread'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'status_open'.tr(),
                isSelected: provider.selectedStatusFilter == 'open',
                onSelected: () => provider.setStatusFilter('open'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'status_in_progress'.tr(),
                isSelected: provider.selectedStatusFilter == 'in_progress',
                onSelected: () => provider.setStatusFilter('in_progress'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'reopen_requested'.tr(),
                isSelected: provider.selectedStatusFilter == 'reopen_requested',
                countBadge: provider.reopenRequestedCount > 0 ? provider.reopenRequestedCount : null,
                badgeColor: AppColors.error,
                onSelected: () => provider.setStatusFilter('reopen_requested'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'status_resolved'.tr(),
                isSelected: provider.selectedStatusFilter == 'resolved',
                onSelected: () => provider.setStatusFilter('resolved'),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'status_closed'.tr(),
                isSelected: provider.selectedStatusFilter == 'closed',
                onSelected: () => provider.setStatusFilter('closed'),
              ),

              const Spacer(),

              // Category dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SupportCategory?>(
                    value: provider.selectedCategory,
                    hint: Text('all_categories'.tr(), style: AppTextStyles.body2),
                    items: [
                      DropdownMenuItem<SupportCategory?>(value: null, child: Text('all_categories'.tr())),
                      ...SupportCategory.values.map((c) {
                        return DropdownMenuItem<SupportCategory?>(value: c, child: Text(c.labelKey.tr()));
                      }),
                    ],
                    onChanged: (cat) => provider.setCategoryFilter(cat),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Priority dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SupportTicketPriority?>(
                    value: provider.selectedPriority,
                    hint: Text('all_priorities'.tr(), style: AppTextStyles.body2),
                    items: [
                      DropdownMenuItem<SupportTicketPriority?>(
                        value: null,
                        child: Text('all_priorities'.tr()),
                      ),
                      ...SupportTicketPriority.values.map((p) {
                        return DropdownMenuItem<SupportTicketPriority?>(
                          value: p,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(p.labelKey.tr()),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (prio) => provider.setPriorityFilter(prio),
                  ),
                ),
              ),

              if (provider.selectedStatusFilter != 'all' ||
                  provider.selectedCategory != null ||
                  provider.selectedPriority != null ||
                  provider.searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'clear_filters'.tr(),
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 20, color: AppColors.textMuted),
                  onPressed: () => provider.clearFilters(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── Data Table / Error State ─────────────────────────────────
          Expanded(
            child: provider.errorMessage != null && tickets.isEmpty && !provider.isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          provider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body2.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => provider.fetchTickets(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('retry'.tr()),
                        ),
                      ],
                    ),
                  )
                : AppDataTable(
                    isLoading: provider.isLoading,
                    emptyMessage: 'no_support_tickets_found'.tr(),
                    columns: [
                      AppDataColumn(label: 'ticket_number'.tr(), flex: 1.5),
                      AppDataColumn(label: 'broker'.tr(), flex: 2.0),
                      AppDataColumn(label: 'category'.tr(), flex: 1.5),
                      AppDataColumn(label: 'subject'.tr(), flex: 2.5),
                      AppDataColumn(label: 'priority'.tr(), flex: 1.2),
                      AppDataColumn(label: 'status'.tr(), flex: 1.3),
                      AppDataColumn(label: 'last_activity'.tr(), flex: 1.8),
                      AppDataColumn(label: 'actions'.tr(), flex: 1.2),
                    ],
                    rows: tickets.map((ticket) {
                      return DataRowItem(
                        cells: [
                          // Ticket # & Reopen indicator
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ticket.ticketNumber,
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (ticket.unreadCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${ticket.unreadCount} NEW',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              if (ticket.reopenRequested) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.errorBorder),
                                  ),
                                  child: const Text(
                                    'REOPEN',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Broker & Requester
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ticket.brokerBusinessName ?? 'Broker',
                                style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                ticket.fullName,
                                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),

                          // Category
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket.categoryEnum.labelKey.tr(),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Subject
                          Text(
                            ticket.subject,
                            style: AppTextStyles.body2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Priority
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: ticket.priorityEnum.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ticket.priorityEnum.labelKey.tr(),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ticket.priorityEnum.color,
                                ),
                              ),
                            ],
                          ),

                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ticket.statusEnum.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket.statusEnum.labelKey.tr(),
                              style: AppTextStyles.caption.copyWith(
                                color: ticket.statusEnum.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Last Activity
                          Text(
                            _formatDate(ticket.lastMessageAt ?? ticket.updatedAt),
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),

                          // Actions: Chat & Manage
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'open_broker_chat'.tr(),
                                    onPressed: () {
                                      provider.markTicketAsRead(ticket.id, ticket.chatRoomId);
                                      AdminChatDialog.show(context, supportTicket: ticket);
                                    },
                                  ),
                                  if (ticket.unreadCount > 0)
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                          '${ticket.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_note_rounded,
                                  size: 20,
                                  color: AppColors.iconDefault,
                                ),
                                tooltip: 'manage_ticket'.tr(),
                                onPressed: () => AdminTicketDetailDialog.show(context, ticket),
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          // ── Pagination ────────────────────────────────────────────────
          PaginationWidget(
            currentPage: provider.currentPage,
            totalPages: provider.totalPages,
            totalCount: provider.totalFilteredCount,
            onPageChanged: (page) => provider.setPage(page),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert ? AppColors.errorBorder : AppColors.border,
          width: isAlert ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: AppTextStyles.heading2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isAlert ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    int? countBadge,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (countBadge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : (badgeColor ?? AppColors.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  countBadge.toString(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
