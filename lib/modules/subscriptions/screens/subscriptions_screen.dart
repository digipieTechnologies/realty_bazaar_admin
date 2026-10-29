import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/subscriptions/subscriptions_provider.dart';
import '../../../widgets/common/app_data_table.dart';
import '../../../widgets/common/pagination_widget.dart';
import '../../../widgets/toast/app_toast.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<SubscriptionsProvider>();
      prov.fetchPlans();
      prov.fetchSubscriptions();
      prov.fetchPayments();
    });
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('Subscriptions'),
        elevation: 0,
        backgroundColor: context.backgroundColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'Subscriptions'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PlansTab(),
          _SubscriptionsTab(),
          _PaymentsTab(),
        ],
      ),
    );
  }
}

// ── Plans Tab ─────────────────────────────────────────────────────────────────

class _PlansTab extends StatelessWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SubscriptionsProvider>();

    if (prov.plansLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.plans.isEmpty) {
      return const Center(child: Text('No subscription plans found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: prov.plans.map((plan) => _PlanCard(plan: plan)).toList(),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<SubscriptionsProvider>();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: plan.isPopular ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(plan.title,
                        style: AppTextStyles.body1
                            .copyWith(fontWeight: FontWeight.bold)),
                  ),
                  if (plan.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Popular',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '₹${plan.amount.toStringAsFixed(0)}',
                style: AppTextStyles.heading1
                    .copyWith(color: AppColors.primary, fontSize: 28),
              ),
              Text(plan.billingType,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Text(plan.description, style: AppTextStyles.body2),
              const SizedBox(height: 12),
              ...plan.benefits.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(child: Text(b, style: AppTextStyles.caption)),
                    ]),
                  )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(plan.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                          color: plan.isActive
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Switch(
                    value: plan.isActive,
                    onChanged: (val) async {
                      final ok = await prov.togglePlanActive(plan.id, val);
                      if (ok && context.mounted) {
                        AppToast.showSuccess(
                            val ? 'Plan Activated' : 'Plan Deactivated',
                            'Plan "${plan.title}" updated.');
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subscriptions Tab ─────────────────────────────────────────────────────────

class _SubscriptionsTab extends StatelessWidget {
  const _SubscriptionsTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SubscriptionsProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: AppDataTable(
              isLoading: prov.subsLoading,
              columns: const [
                AppDataColumn(label: 'Broker', flex: 2),
                AppDataColumn(label: 'Plan', flex: 2),
                AppDataColumn(label: 'Amount', flex: 1),
                AppDataColumn(label: 'Start Date', flex: 2),
                AppDataColumn(label: 'End Date', flex: 2),
                AppDataColumn(label: 'Status', flex: 1),
              ],
              rows: prov.subscriptions
                  .map((s) => _buildSubRow(s))
                  .toList(),
            ),
          ),
          PaginationWidget(
            pagination: prov.subsPagination,
            currentPage: prov.subsCurrentPage,
            totalPages: prov.subsTotalPages,
            totalCount: prov.subsTotalCount,
            isLoading: prov.subsLoading,
            onPageChanged: prov.setSubsPage,
          ),
        ],
      ),
    );
  }

  DataRowItem _buildSubRow(UserSubscriptionModel sub) {
    final isActive = sub.isActive;
    return DataRowItem(
      cells: [
        Text(sub.broker?.businessName ?? sub.brokerId,
            style: AppTextStyles.body2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(sub.plan?.title ?? sub.planCode,
                style:
                    AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
            Text(sub.planCode,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        Text('₹${sub.amount.toStringAsFixed(0)}',
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
        Text(DateFormat('dd MMM yyyy').format(sub.startDate),
            style: AppTextStyles.body2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('dd MMM yyyy').format(sub.endDate),
                style: AppTextStyles.body2),
            Text('${sub.daysRemaining}d remaining',
                style: AppTextStyles.caption.copyWith(
                    color: sub.daysRemaining < 7
                        ? AppColors.error
                        : AppColors.textSecondary)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.successLight : AppColors.errorLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isActive ? 'Active' : 'Expired',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Payments Tab ──────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SubscriptionsProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPaymentFilters(context, prov),
          const SizedBox(height: 12),
          Expanded(
            child: AppDataTable(
              isLoading: prov.paysLoading,
              columns: const [
                AppDataColumn(label: 'Broker', flex: 2),
                AppDataColumn(label: 'Amount', flex: 1),
                AppDataColumn(label: 'Purpose', flex: 2),
                AppDataColumn(label: 'Provider', flex: 1),
                AppDataColumn(label: 'Date', flex: 2),
                AppDataColumn(label: 'Status', flex: 1),
              ],
              rows: prov.payments.map(_buildPayRow).toList(),
            ),
          ),
          PaginationWidget(
            pagination: prov.paysPagination,
            currentPage: prov.paysCurrentPage,
            totalPages: prov.paysTotalPages,
            totalCount: prov.paysTotalCount,
            isLoading: prov.paysLoading,
            onPageChanged: prov.setPaysPage,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentFilters(
      BuildContext context, SubscriptionsProvider prov) {
    const statuses = ['All', 'pending', 'success', 'failed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          final isSelected = s == 'All'
              ? prov.paysStatusFilter == null
              : prov.paysStatusFilter == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(s[0].toUpperCase() + s.substring(1)),
              selected: isSelected,
              onSelected: (_) => prov.setPaysStatusFilter(s),
            ),
          );
        }).toList(),
      ),
    );
  }

  DataRowItem _buildPayRow(UserPaymentModel pay) {
    final (bg, fg) = switch (pay.status) {
      'success' => (AppColors.successLight, AppColors.success),
      'failed' => (AppColors.errorLight, AppColors.error),
      _ => (AppColors.warningLight, AppColors.warning),
    };
    return DataRowItem(
      cells: [
        Text(pay.broker?.businessName ?? pay.brokerId,
            style: AppTextStyles.body2),
        Text('₹${pay.amount.toStringAsFixed(0)}',
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
        Text(pay.purpose.replaceAll('_', ' '),
            style: AppTextStyles.body2),
        Text(pay.paymentProvider, style: AppTextStyles.body2),
        Text(DateFormat('dd MMM yyyy').format(pay.createdAt),
            style: AppTextStyles.body2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Text(
            pay.status[0].toUpperCase() + pay.status.substring(1),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: fg),
          ),
        ),
      ],
    );
  }
}
