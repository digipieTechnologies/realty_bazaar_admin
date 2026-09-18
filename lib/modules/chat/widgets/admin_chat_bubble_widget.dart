// File: lib/modules/chat/widgets/admin_chat_bubble_widget.dart
// Purpose: Responsive chat bubble for admin view supporting sender distinction, attachments, replies, and edits.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../widgets/common/cached_image.dart';
import '../../../widgets/toast/app_toast.dart';

class AdminChatBubbleWidget extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AdminChatBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  void _copyText(BuildContext context) {
    if (message.message != null && message.message!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: message.message!));
      AppToast.showSuccess('Copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormatted = DateFormat('hh:mm a').format(message.createdAt.toLocal());
    final senderTitle = isMe ? 'Admin' : 'Broker';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              child: const Icon(Icons.business_rounded, size: 14, color: AppColors.secondary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      senderTitle,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeFormatted,
                      style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  onLongPress: () => _showContextMenu(context),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isMe ? 14 : 2),
                        bottomRight: Radius.circular(isMe ? 2 : 14),
                      ),
                      border: isMe ? null : Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Reply quote banner
                        if (message.replyMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : AppColors.border.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border(
                                left: BorderSide(color: isMe ? Colors.white : AppColors.primary, width: 3),
                              ),
                            ),
                            child: Text(
                              message.replyMessage?.message ?? 'Attachment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],

                        // Attachments (if any)
                        if (message.medias.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: message.medias.map((m) {
                              final isImg =
                                  m.url != null &&
                                  (m.url!.toLowerCase().endsWith('.png') ||
                                      m.url!.toLowerCase().endsWith('.jpg') ||
                                      m.url!.toLowerCase().endsWith('.jpeg') ||
                                      m.type?.contains('image') == true);
                              if (isImg && m.url != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedImage(
                                    imageUrl: m.url!,
                                    width: 140,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_file_rounded,
                                      size: 16,
                                      color: isMe ? Colors.white : AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      m.url?.split('/').last ?? 'Document',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMe ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          if (message.message != null && message.message!.trim().isNotEmpty)
                            const SizedBox(height: 6),
                        ],

                        // Message text
                        if (message.message != null && message.message!.trim().isNotEmpty)
                          Text(
                            message.message!,
                            style: AppTextStyles.body2.copyWith(
                              color: isMe ? Colors.white : AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),

                        // Edited tag
                        if (message.isEdited) ...[
                          const SizedBox(height: 2),
                          Text(
                            'edited',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontStyle: FontStyle.italic,
                              color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.support_agent_rounded, size: 14, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded, size: 20),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(ctx);
                _copyText(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply_rounded, size: 20),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                onReply?.call();
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit_rounded, size: 20),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                title: const Text('Delete Message', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
