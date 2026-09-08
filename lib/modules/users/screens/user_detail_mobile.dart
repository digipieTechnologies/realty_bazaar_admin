// File: lib/modules/users/screens/user_detail_mobile.dart
// Purpose: Mobile view for User Detail screen with interactive cover image upload.

import 'dart:typed_data';

import 'package:brokerflow_admin/app/common_ext.dart';
import 'package:brokerflow_admin/models/user_role.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_colors.dart';
import '../../../app/context_ext.dart';
import '../../../core/enums/gender_enum.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/attachment_service.dart';
import '../../../models/attachment_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/users/users_provider.dart';
import '../../../widgets/common/cover_image_widget.dart';
import '../../../widgets/dialogs/confirm_dialog.dart';
import '../../../widgets/dialogs/user_edit_dialog.dart';
import '../../../widgets/toast/app_toast.dart';

class UserDetailMobile extends StatefulWidget {
  final UserModel user;
  final UsersProvider usersProv;
  final Future<void> Function() onDelete;

  const UserDetailMobile({super.key, required this.user, required this.usersProv, required this.onDelete});

  @override
  State<UserDetailMobile> createState() => _UserDetailMobileState();
}

class _UserDetailMobileState extends State<UserDetailMobile> {
  final AttachmentService _attachmentService = AttachmentService();
  AttachmentModel? _coverImage;
  bool _isLoadingCover = false;

  @override
  void initState() {
    super.initState();
    _coverImage = widget.user.coverImage;
  }

  @override
  void didUpdateWidget(covariant UserDetailMobile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user.coverImage != oldWidget.user.coverImage) {
      _coverImage = widget.user.coverImage;
    }
  }

  Future<void> _onAddOrReplaceCover() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || widget.user.id == null) return;

    final Uint8List? bytes = file.bytes;
    if (bytes == null) {
      AppToast.showError('File Error', 'Could not read file data');
      return;
    }

    setState(() => _isLoadingCover = true);

    try {
      final newCover = await _attachmentService.setCoverImageGeneric(
        table: 'users',
        entityId: widget.user.id!,
        fileName: file.name,
        bytes: bytes,
      );

      if (!mounted) return;
      setState(() {
        _coverImage = newCover;
        _isLoadingCover = false;
      });

      final updatedUser = widget.user.copyWith(coverImage: newCover);
      widget.usersProv.updateLocalUser(updatedUser);
      AppToast.showSuccess('Cover Image Updated');
    } on ApiException catch (e) {
      if (mounted) setState(() => _isLoadingCover = false);
      AppToast.showError('Upload Error', e.message);
    } catch (e) {
      if (mounted) setState(() => _isLoadingCover = false);
      AppToast.showError('Upload Error', e.toString());
    }
  }

  Future<void> _onRemoveCover() async {
    final confirmed = await ConfirmDialog.showResponsive(
      context: context,
      title: 'users_delete_cover_image_title'.tr(),
      message: 'users_delete_cover_image_msg'.tr(),
      confirmLabel: 'delete'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || widget.user.id == null) return;

    final oldCover = _coverImage;
    setState(() => _coverImage = null);

    try {
      await _attachmentService.removeCoverImageGeneric(table: 'users', entityId: widget.user.id!);

      if (!mounted) return;
      final updatedUser = widget.user.copyWith(coverImage: null);
      widget.usersProv.updateLocalUser(updatedUser);
      AppToast.showSuccess('Cover Image Removed');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _coverImage = oldCover);
        AppToast.showError('Remove Error', e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _coverImage = oldCover);
        AppToast.showError('Remove Error', e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final user = widget.user;
    final isActive = user.isActive ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name ?? 'users_details'.tr(), style: context.appBarTitle),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 40),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                user.avatarImage(context: context, width: 48, height: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name?.wordCap() ?? '-',
                        style: context.cardTitle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(user.phone ?? user.email ?? '-', style: context.cardSubtitle),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.primary : AppColors.textMuted).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isActive ? AppColors.primary : AppColors.textMuted).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    isActive ? 'users_active'.tr() : 'users_inactive'.tr(),
                    style: context.badgeText.copyWith(
                      fontSize: 11,
                      color: isActive ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Profile Info Section
          Text('users_profile_info'.tr(), style: context.sectionTitle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
            ),
            child: Column(
              children: [
                _buildInfoRow(context, colorScheme, Icons.person_outline, 'name'.tr(), user.name),
                const Divider(height: 20),
                _buildInfoRow(context, colorScheme, Icons.phone_outlined, 'phone'.tr(), user.phone),
                const Divider(height: 20),
                _buildInfoRow(context, colorScheme, Icons.email_outlined, 'email'.tr(), user.email),
                const Divider(height: 20),
                _buildInfoRow(context, colorScheme, Icons.badge_outlined, 'role'.tr(), user.role.displayName),
                const Divider(height: 20),
                _buildInfoRow(
                  context,
                  colorScheme,
                  user.gender.icon,
                  'users_gender'.tr(),
                  user.gender.displayName(context),
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  context,
                  colorScheme,
                  Icons.cake_outlined,
                  'users_dob'.tr(),
                  user.dob != null
                      ? '${user.formattedDob}${user.ageInYears != null ? ' (${user.ageInYears} yrs)' : ''}'
                      : '-',
                ),
                const Divider(height: 20),
                _buildInfoRow(
                  context,
                  colorScheme,
                  Icons.notes_outlined,
                  'users_notes'.tr(),
                  user.notes ?? '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cover Image Section
          Text('users_cover_image'.tr(), style: context.sectionTitle),
          const SizedBox(height: 10),
          CoverImageWidget(
            coverImage: _coverImage,
            isLoading: _isLoadingCover,
            onAddOrReplace: _onAddOrReplaceCover,
            onRemove: _coverImage != null ? _onRemoveCover : null,
            height: 160,
          ),
          const SizedBox(height: 28),

          // Stacked Mobile Actions
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onDelete(),
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              label: Text('users_delete_user'.tr(), style: TextStyle(color: colorScheme.error)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                UserEditDialog.show(
                  context,
                  user: user,
                  onSave: (updated) => widget.usersProv.updateUser(updated),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text('users_edit_user'.tr()),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String? value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.cardSubtitle.copyWith(fontSize: 11)),
              const SizedBox(height: 2),
              SelectableText(
                value ?? '-',
                style: context.cardTitle.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
