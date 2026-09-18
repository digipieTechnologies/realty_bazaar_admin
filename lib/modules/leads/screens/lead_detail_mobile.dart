// File: lib/modules/leads/screens/lead_detail_mobile.dart
// Purpose: Super Admin mobile view for social lead details with single-column card layout.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/common_ext.dart';
import '../../../app/context_ext.dart';
import '../../../models/media_model.dart';
import '../../../models/property_model.dart';
import '../../../models/social_lead_model.dart';
import '../../../providers/leads/admin_leads_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_lead_status_badge.dart';
import '../../../widgets/common/app_platform_badge.dart';
import '../../../widgets/common/cached_image.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/add_lead_dialog.dart';
import '../widgets/reassign_broker_dialog.dart';

class LeadDetailMobile extends StatelessWidget {
  final SocialLeadModel lead;

  const LeadDetailMobile({super.key, required this.lead});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }

  Future<void> _launchUrlSafe(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          AppToast.showError('error'.tr(), 'Cannot launch action: $urlString');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError('error'.tr(), e.toString());
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.showResponsive(
      context: context,
      title: 'leads_delete_lead'.tr(),
      message: 'leads_delete_confirm_msg'.tr(),
      confirmLabel: 'delete'.tr(),
      cancelLabel: 'cancel'.tr(),
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<AdminLeadsProvider>().deleteLead(lead.id!);
      if (success && context.mounted) {
        AppToast.showSuccess('leads_toast_deleted'.tr());
        context.go(AppRoutes.socialLeads);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = lead.socialPost?.platform?.toLowerCase() ?? '';
    final isInstagram = platform == 'instagram';
    final isFacebook = platform == 'facebook';

    final Gradient coverGradient = isInstagram
        ? const LinearGradient(
            colors: [AppColors.instagramStart, AppColors.instagramMiddle, AppColors.instagramEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (isFacebook
              ? const LinearGradient(
                  colors: [AppColors.facebook, AppColors.facebookDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [context.primaryColor, context.primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ));

    final PropertyModel? property = lead.socialPost?.property;
    final propertyTitle = (property?.propertyTitle.isNotEmpty == true)
        ? property!.propertyTitle
        : (lead.propertyDetails?.isNotEmpty == true
              ? lead.propertyDetails!
              : (lead.socialPost?.caption ?? ''));

    final notesText = lead.notes;
    final mediaList = lead.socialPost?.medias ?? property?.medias;
    final hasPermalink = lead.socialPost?.permalink?.isNotEmpty == true;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text('leads_detail_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'leads_edit_lead'.tr(),
            onPressed: () => AddLeadDialog.show(context, leadToEdit: lead),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: context.colorScheme.error),
            tooltip: 'leads_delete_lead'.tr(),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card with Action Buttons
            _buildHeroCard(context, coverGradient, isInstagram, isFacebook),
            const SizedBox(height: 16),

            // Contact Info
            _buildContactCard(context),
            const SizedBox(height: 16),

            // Assigned Broker
            _buildAssignedBrokerCard(context),
            const SizedBox(height: 16),

            // Inquired Property
            if (propertyTitle.isNotEmpty) ...[
              _buildPropertyCard(context, propertyTitle, property, mediaList),
              const SizedBox(height: 16),
            ],

            // Inquiry Notes
            if (notesText != null && notesText.trim().isNotEmpty) ...[
              _buildNotesCard(context, notesText.trim()),
              const SizedBox(height: 16),
            ],

            // Social Post Link
            if (hasPermalink) ...[
              AppButton.solid(
                text: 'leads_view_social_post'.tr(),
                iconData: Icons.open_in_new_rounded,
                width: double.infinity,
                height: 46,
                borderRadius: 12,
                onPressed: () => _launchUrlSafe(context, lead.socialPost!.permalink!),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, Gradient coverGradient, bool isInstagram, bool isFacebook) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 100.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: coverGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: AppLeadStatusBadge(
                        isSolid: true,
                        status: lead.status,
                        onStatusChanged: (newStatus) async {
                          final success = await context.read<AdminLeadsProvider>().updateLeadStatus(
                            lead.id!,
                            newStatus,
                          );
                          if (success && context.mounted) {
                            AppToast.showSuccess('leads_toast_status_updated'.tr());
                          }
                        },
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: AppPlatformBadge(
                        platform: lead.socialPost?.platform,
                        isHeaderStyle: true,
                        iconSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -32.0,
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    lead.userName.isNotEmpty ? lead.userName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.primaryColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  lead.userName.isNotEmpty ? lead.userName : 'leads_prospect_fallback'.tr(),
                  style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'leads_received_at'.tr(args: [_formatDate(lead.createdAt)]),
                  style: AppTextStyles.caption.copyWith(color: context.textColorMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCallout(
                  context,
                  label: 'leads_action_call'.tr(),
                  icon: Icons.phone_in_talk_rounded,
                  gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primary700]),
                  shadowColor: AppColors.primary600,
                  onTap: () {
                    if (lead.phone.isNotEmpty) {
                      _launchUrlSafe(context, 'tel:${lead.contactNumber}');
                    }
                  },
                ),
                _buildActionCallout(
                  context,
                  label: 'leads_action_sms'.tr(),
                  icon: Icons.chat_bubble_outline_rounded,
                  gradient: const LinearGradient(colors: [AppColors.primary400, AppColors.primary500]),
                  shadowColor: AppColors.primary400,
                  onTap: () {
                    if (lead.phone.isNotEmpty) {
                      _launchUrlSafe(context, 'sms:${lead.contactNumber}');
                    }
                  },
                ),
                _buildActionCallout(
                  context,
                  label: 'leads_action_whatsapp'.tr(),
                  icon: Icons.chat_rounded,
                  gradient: const LinearGradient(colors: [AppColors.whatsapp, AppColors.whatsappDark]),
                  shadowColor: AppColors.whatsapp,
                  onTap: () {
                    if (lead.phone.isNotEmpty) {
                      _launchUrlSafe(context, lead.buildWhatsappUrl());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCallout(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Gradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(child: Icon(icon, color: Colors.white, size: 20)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: context.textColor),
        ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'leads_contact_info'.tr(),
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'leads_phone_number'.tr(),
            lead.contactNumber,
            trailing: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: lead.contactNumber));
                AppToast.showSuccess('leads_copied_toast'.tr());
              },
              child: Icon(Icons.copy_rounded, size: 16, color: context.primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            'leads_platform_source'.tr(),
            lead.socialPost?.platform ?? 'leads_direct_inquiry'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedBrokerCard(BuildContext context) {
    final broker = lead.broker;
    final hasBroker = broker != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'leads_assigned_broker'.tr(),
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
              AppButton.outline(
                text: hasBroker ? 'leads_reassign_broker'.tr() : 'leads_assign_broker'.tr(),
                height: 32,
                onPressed: () => ReassignBrokerDialog.show(context, lead),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context, 'leads_agency_name'.tr(), broker?.businessName ?? 'leads_unassigned'.tr()),
          if (hasBroker) ...[
            const SizedBox(height: 8),
            _buildInfoRow(context, 'leads_broker_plan'.tr(), broker.plan ?? 'Standard'),
          ],
        ],
      ),
    );
  }

  Widget _buildPropertyCard(
    BuildContext context,
    String title,
    PropertyModel? property,
    List<dynamic>? mediaList,
  ) {
    final address = property?.address?.fullAddress;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'leads_inquired_property'.tr(),
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
                if (property != null && property.price > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    property.price.formatCurrency,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ],
                if (address != null && address.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(address, style: AppTextStyles.caption.copyWith(color: context.textColorMuted)),
                ],
              ],
            ),
          ),
          if (mediaList != null && mediaList.isNotEmpty) ...[
            Divider(height: 1, color: context.borderColor),
            Container(
              padding: const EdgeInsets.all(12),
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mediaList.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final media = mediaList[i];
                  final url = media is MediaModel ? media.url : media.toString();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedImage(imageUrl: url, width: 110, height: 76, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'leads_inquiry_notes'.tr(),
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(notes, style: AppTextStyles.body2),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: context.textColorMuted)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ],
    );
  }
}
