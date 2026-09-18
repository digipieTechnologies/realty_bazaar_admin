// File: lib/modules/support/screens/admin_support_mobile.dart
// Purpose: Super Admin mobile view for support tickets featuring card-based list layout, horizontal metric chips, and quick action dialogs.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../providers/support/admin_support_provider.dart';
import '../../../widgets/common/app_search_field.dart';
import '../../chat/dialogs/admin_chat_dialog.dart';
import '../widgets/admin_create_ticket_dialog.dart';
import '../widgets/admin_ticket_detail_dialog.dart';

class AdminSupportMobile extends StatelessWidget {
  const AdminSupportMobile({super.key});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }

  void _showFilterModal(BuildContext context) {
    final provider = context.read<AdminSupportProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('filters'.tr(), style: AppTextStyles.heading3),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),

                // Category
                Text('category'.tr(), style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('common.all'.tr()),
                      selected: provider.selectedCategory == null,
                      onSelected: (_) {
                        provider.setCategoryFilter(null);
                        setModalState(() {});
                      },
                    ),
                    ...SupportCategory.values.map((c) {
                      return ChoiceChip(
                        label: Text(c.labelKey.tr()),
                        selected: provider.selectedCategory == c,
                        onSelected: (_) {
                          provider.setCategoryFilter(c);
                          setModalState(() {});
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Priority
                Text('priority'.tr(), style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('common.all'.tr()),
                      selected: provider.selectedPriority == null,
                      onSelected: (_) {
                        provider.setPriorityFilter(null);
                        setModalState(() {});
                      },
                    ),
                    ...SupportTicketPriority.values.map((p) {
                      return ChoiceChip(
                        label: Text(p.labelKey.tr()),
                        selected: provider.selectedPriority == p,
                        onSelected: (_) {
                          provider.setPriorityFilter(p);
                          setModalState(() {});
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: Text('clear_filters'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => Navigator.pop(context),
                        child: Text('apply'.tr(), style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminSupportProvider>();
    final tickets = provider.allFilteredTickets;

    return RefreshIndicator(
      onRefresh: () => provider.fetchTickets(showLoading: false),
      child: Column(
        children: [
          // ── Search & Filter Row ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchBar(
              hintText: 'search_tickets_hint'.tr(),
              onSearch: (q) => provider.setSearchQuery(q),
              isMobile: true,
              onFilter: () => _showFilterModal(context),
              activeFilterCount:
                  (provider.selectedCategory != null ? 1 : 0) + (provider.selectedPriority != null ? 1 : 0),
              onAdd: () => AdminCreateTicketDialog.show(context),
            ),
          ),

          // ── Status Chips ──────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('common.all'.tr(), 'all', provider),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Unread',
                  'unread',
                  provider,
                  badge: provider.unreadTicketsCount > 0 ? provider.unreadTicketsCount : null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip('status_open'.tr(), 'open', provider),
                const SizedBox(width: 8),
                _buildFilterChip('status_in_progress'.tr(), 'in_progress', provider),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'reopen_requested'.tr(),
                  'reopen_requested',
                  provider,
                  badge: provider.reopenRequestedCount > 0 ? provider.reopenRequestedCount : null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip('status_resolved'.tr(), 'resolved', provider),
                const SizedBox(width: 8),
                _buildFilterChip('status_closed'.tr(), 'closed', provider),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Tickets List ──────────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null && tickets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
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
                    ),
                  )
                : tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.support_agent_rounded,
                          size: 54,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'no_support_tickets_found'.tr(),
                          style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _buildTicketCard(context, ticket);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusKey, AdminSupportProvider provider, {int? badge}) {
    final isSelected = provider.selectedStatusFilter == statusKey;
    return InkWell(
      onTap: () => provider.setStatusFilter(statusKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, SupportTicketModel ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ticket.reopenRequested ? AppColors.errorBorder : AppColors.border,
          width: ticket.reopenRequested ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Ticket Number & Status Pill
            Row(
              children: [
                Text(
                  ticket.ticketNumber,
                  style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                if (ticket.unreadCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${ticket.unreadCount} NEW',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ticket.statusEnum.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.statusEnum.labelKey.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ticket.statusEnum.color,
                    ),
                  ),
                ),
              ],
            ),

            // Reopen warning alert
            if (ticket.reopenRequested) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'reopen_requested'.tr(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Broker business name & requester
            Text(
              ticket.brokerBusinessName ?? 'Broker',
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${ticket.fullName} • ${ticket.email}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // Subject & Description snippet
            Text(
              ticket.subject,
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              ticket.description,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 20, color: AppColors.border),

            // Footer Row: Priority, Date, and Actions
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: ticket.priorityEnum.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  ticket.priorityEnum.labelKey.tr(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ticket.priorityEnum.color,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatDate(ticket.updatedAt),
                  style: AppTextStyles.caption.copyWith(fontSize: 10.5, color: AppColors.textMuted),
                ),
                const Spacer(),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.primary),
                      onPressed: () {
                        context.read<AdminSupportProvider>().markTicketAsRead(ticket.id, ticket.chatRoomId);
                        AdminChatDialog.show(context, supportTicket: ticket);
                      },
                    ),
                    if (ticket.unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
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
                  icon: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.iconDefault),
                  onPressed: () => AdminTicketDetailDialog.show(context, ticket),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
