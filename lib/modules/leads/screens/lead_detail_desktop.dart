// File: lib/modules/leads/screens/lead_detail_desktop.dart
// Purpose: Super Admin desktop two-column view for social lead details replicating broker app hero presentation with admin broker assignment card and actions.

import 'package:brokerflow_admin/widgets/media/full_screen_media_viewer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/common_ext.dart';
import '../../../app/context_ext.dart';
import '../../../models/media_model.dart';
import '../../../models/property_enums.dart';
import '../../../models/property_model.dart';
import '../../../models/social_lead_model.dart';
import '../../../providers/leads/admin_leads_provider.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/common/app_breadcrumbs.dart';
import '../../../widgets/common/app_platform_badge.dart';
import '../../../widgets/common/cached_image.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/add_lead_dialog.dart';
import '../widgets/reassign_broker_dialog.dart';

class LeadDetailDesktop extends StatelessWidget {
  final SocialLeadModel lead;

  const LeadDetailDesktop({super.key, required this.lead});

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

    final child1 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(context, coverGradient, isInstagram, isFacebook),
        const SizedBox(height: 16),
        _buildContactCard(context),
        const SizedBox(height: 16),
        _buildAssignedBrokerCard(context),
      ],
    );

    final child2 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (propertyTitle.isNotEmpty) ...[
          _buildPropertyCard(context, propertyTitle, property, mediaList),
          const SizedBox(height: 16),
        ],
        if (notesText != null && notesText.trim().isNotEmpty) ...[
          _buildNotesCard(context, notesText.trim()),
          const SizedBox(height: 16),
        ],
        if (hasPermalink) ...[
          _buildSocialPostButton(context, lead.socialPost!.permalink!),
          const SizedBox(height: 16),
        ],
        _buildAdminControlsCard(context),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb Navigation
              AppBreadcrumbs(
                items: [
                  BreadcrumbItem(label: 'tab_leads'.tr(), onTap: () => context.go(AppRoutes.socialLeads)),
                  BreadcrumbItem(label: lead.userName.isNotEmpty ? lead.userName : 'leads_detail_title'.tr()),
                ],
              ),
              const SizedBox(height: 16),

              // Two-column layout
              ResponsiveBuilder(
                builder: (context, sizingInformation) {
                  final parentDeviceType = getDeviceType(sizingInformation.localWidgetSize);
                  final isDesktop = parentDeviceType == DeviceScreenType.desktop;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Left Column: Profile Hero, Action Callouts & Contact Info ─
                        Expanded(flex: 3, child: child1),
                        const SizedBox(width: 20),

                        // ── Right Column: Property Details, Notes & Post Button ──────
                        Expanded(flex: 2, child: child2),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [child1, const SizedBox(height: 20), child2],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Hero Profile Card with Banner, Floating Avatar & Quick Action Buttons ─
  Widget _buildHeroCard(BuildContext context, Gradient coverGradient, bool isInstagram, bool isFacebook) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Banner
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 110.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: coverGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        isFacebook
                            ? Icons.facebook_rounded
                            : (isInstagram ? Icons.camera_alt_rounded : Icons.public_rounded),
                        size: 90,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: AppPlatformBadge(
                        platform: lead.socialPost?.platform,
                        isHeaderStyle: true,
                        iconSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Floating User Avatar
              Positioned(
                bottom: -36.0,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          lead.userName.isNotEmpty ? lead.userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 44),

          // User Name & Timestamp
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: context.textColorMuted),
                    const SizedBox(width: 4),
                    Text(
                      'leads_received_at'.tr(args: [_formatDate(lead.createdAt)]),
                      style: AppTextStyles.caption.copyWith(color: context.textColorMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 20),

          // 3 Action Buttons (Call, Message, WhatsApp)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(child: Icon(icon, color: Colors.white, size: 22)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: context.textColor,
          ),
        ),
      ],
    );
  }

  // ── 2. Contact Information Card ─────────────────────────────────────────────
  Widget _buildContactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_pin_rounded, color: context.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'leads_contact_info'.tr(),
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoTile(
            context,
            icon: Icons.phone_outlined,
            label: 'leads_phone_number'.tr(),
            value: lead.contactNumber.isNotEmpty ? lead.contactNumber : '--',
            trailing: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: lead.contactNumber));
                AppToast.showSuccess('leads_copied_toast'.tr());
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: context.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'leads_copy'.tr(),
                      style: TextStyle(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            context,
            icon: Icons.public_rounded,
            label: 'leads_platform_source'.tr(),
            value: lead.socialPost?.platform ?? 'leads_direct_inquiry'.tr(),
          ),
        ],
      ),
    );
  }

  // ── 3. Admin Assigned Broker Card ───────────────────────────────────────────
  Widget _buildAssignedBrokerCard(BuildContext context) {
    final broker = lead.broker;
    final hasBroker = broker != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business_rounded, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'leads_assigned_broker'.tr(),
                  style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              AppButton.outline(
                text: hasBroker ? 'leads_reassign_broker'.tr() : 'leads_assign_broker'.tr(),
                height: 34,
                iconData: Icons.swap_horiz_rounded,
                onPressed: () => ReassignBrokerDialog.show(context, lead),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasBroker) ...[
            _buildInfoTile(
              context,
              icon: Icons.storefront_rounded,
              label: 'leads_agency_name'.tr(),
              value: broker.businessName ?? 'Broker #${broker.id?.substring(0, 6)}',
            ),
            const SizedBox(height: 12),
            _buildInfoTile(
              context,
              icon: Icons.verified_user_rounded,
              label: 'leads_broker_plan'.tr(),
              value: broker.plan ?? 'Standard',
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.borderColor),
              ),
              child: Text(
                'leads_unassigned_desc'.tr(),
                style: AppTextStyles.caption.copyWith(color: context.textColorMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. Inquired Property Card ───────────────────────────────────────────────
  Widget _buildPropertyCard(
    BuildContext context,
    String propertyTitle,
    PropertyModel? property,
    List<dynamic>? mediaList,
  ) {
    final priceStr = property != null && property.price > 0 ? property.price.formatCurrency : '';
    final addressStr = property?.address?.fullAddress ?? '';

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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'leads_inquired_property'.tr(),
                      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  propertyTitle,
                  style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (property?.propertyType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property!.propertyType.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: context.primaryColor,
                          ),
                        ),
                      ),
                    if (priceStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          priceStr,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (addressStr.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: context.textColorMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          addressStr,
                          style: AppTextStyles.caption.copyWith(color: context.textColorMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Media Carousel
          if (mediaList != null && mediaList.isNotEmpty) ...[
            Divider(height: 1, color: context.borderColor),
            Container(
              padding: const EdgeInsets.all(16),
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mediaList.length,
                separatorBuilder: (context, i) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final media = mediaList[i];
                  final url = media is MediaModel ? media.url : media.toString();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullScreenMediaViewer(medias: mediaList.cast<MediaModel>(), initialIndex: i),
                          ),
                        );
                      },
                      child: CachedImage(
                        imageUrl: url,
                        width: 130,
                        height: 88,
                        fit: BoxFit.cover,
                        ignoring: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 5. Inquiry Notes Card ───────────────────────────────────────────────────
  Widget _buildNotesCard(BuildContext context, String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notes_rounded, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'leads_inquiry_notes'.tr(),
                style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, color: AppColors.warning, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text(notes, style: AppTextStyles.body2.copyWith(height: 1.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Social Post Link Button ──────────────────────────────────────────────
  Widget _buildSocialPostButton(BuildContext context, String permalink) {
    return AppButton.solid(
      text: 'leads_view_social_post'.tr(),
      iconData: Icons.open_in_new_rounded,
      color: context.primaryColor,
      width: double.infinity,
      height: 46,
      borderRadius: 12,
      onPressed: () => _launchUrlSafe(context, permalink),
    );
  }

  // ── 7. Admin Controls Card ──────────────────────────────────────────────────
  Widget _buildAdminControlsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.outline(
              text: 'leads_edit_lead'.tr(),
              iconData: Icons.edit_outlined,
              height: 42,
              onPressed: () => AddLeadDialog.show(context, leadToEdit: lead),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton.outline(
              text: 'leads_delete_lead'.tr(),
              iconData: Icons.delete_outline_rounded,
              borderColor: context.colorScheme.error,
              textColor: context.colorScheme.error,
              height: 42,
              onPressed: () => _confirmDelete(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: context.backgroundColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: context.textColorMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: context.textColorMuted)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
