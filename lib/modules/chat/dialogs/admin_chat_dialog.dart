// File: lib/modules/chat/dialogs/admin_chat_dialog.dart
// Purpose: Full-featured real-time chat dialog for Super Admins to communicate directly with brokers on support tickets.

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../app/context_ext.dart';
import '../../../models/models.dart';
import '../../../providers/auth/admin_auth_provider.dart';
import '../../../providers/chat/admin_chat_provider.dart';
import '../../../providers/support/admin_support_provider.dart';
import '../../../widgets/toast/app_toast.dart';
import '../widgets/admin_chat_bubble_widget.dart';
import '../widgets/admin_chat_date_separator.dart';
import '../widgets/admin_chat_input_bar_widget.dart';

class AdminChatDialog extends StatefulWidget {
  final SupportTicketModel supportTicket;

  const AdminChatDialog({super.key, required this.supportTicket});

  static Future<void> show(BuildContext context, {required SupportTicketModel supportTicket}) {
    context.read<AdminSupportProvider>().setActiveChatRoom(supportTicket.chatRoomId);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      useSafeArea: !context.isDesktop ? false : true,
      builder: (context) => AdminChatDialog(supportTicket: supportTicket),
    ).then((_) {
      if (context.mounted) {
        context.read<AdminSupportProvider>().setActiveChatRoom(null);
        context.read<AdminSupportProvider>().markTicketAsRead(supportTicket.id, supportTicket.chatRoomId);
      }
    });
  }

  @override
  State<AdminChatDialog> createState() => _AdminChatDialogState();
}

class _AdminChatDialogState extends State<AdminChatDialog> {
  final ScrollController _scrollController = ScrollController();
  ChatMessageModel? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<AdminChatProvider>();
      if (widget.supportTicket.chatRoomId != null) {
        context.read<AdminSupportProvider>().setActiveChatRoom(widget.supportTicket.chatRoomId);
      }
      chatProvider
          .initSupportChatRoom(
            supportTicketId: widget.supportTicket.id,
            brokerId: widget.supportTicket.brokerId,
          )
          .then((_) {
            if (mounted && chatProvider.currentRoom != null) {
              context.read<AdminSupportProvider>().setActiveChatRoom(chatProvider.currentRoom!.id);
            }
          });
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 100.0) {
      final chatProvider = context.read<AdminChatProvider>();
      if (!chatProvider.isLoadingMore && chatProvider.hasMore) {
        chatProvider.fetchMoreMessages();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    try {
      context.read<AdminSupportProvider>().setActiveChatRoom(null);
      context.read<AdminChatProvider>().closeRoom();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _handleSendMessage({required String text, List<MediaModel> attachments = const []}) async {
    final authProvider = context.read<AdminAuthProvider>();
    final adminUser = authProvider.adminUser;
    if (adminUser == null) {
      AppToast.showError('Not authenticated as admin');
      return;
    }

    final chatProvider = context.read<AdminChatProvider>();
    final success = await chatProvider.sendMessage(
      senderId: adminUser.id!,
      message: text,
      attachmentMedias: attachments,
      replyMessageId: _replyingToMessage?.id,
    );

    if (success) {
      setState(() => _replyingToMessage = null);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } else {
      AppToast.showError('Failed to send message');
    }
  }

  void _handleEditMessage(ChatMessageModel msg) {
    final controller = TextEditingController(text: msg.message ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AdminChatProvider>();
              await provider.editMessage(msg.id, controller.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleDeleteMessage(ChatMessageModel msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AdminChatProvider>();
              await provider.deleteMessage(msg.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final dialogWidth = isDesktop ? 680.0 : double.infinity;
    final dialogHeight = isDesktop ? MediaQuery.of(context).size.height * 0.85 : double.infinity;

    final chatProvider = context.watch<AdminChatProvider>();
    final messages = chatProvider.messages;
    final authProvider = context.watch<AdminAuthProvider>();
    final currentAdminId = authProvider.adminUser?.id;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: isDesktop ? BorderRadius.circular(16) : BorderRadius.zero),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: isDesktop ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24) : EdgeInsets.zero,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
        decoration: BoxDecoration(
          borderRadius: isDesktop ? BorderRadius.circular(16) : BorderRadius.zero,
          color: AppColors.surface,
          boxShadow: isDesktop
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20.0,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.supportTicket.ticketNumber,
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.supportTicket.statusEnum.backgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.supportTicket.statusEnum.labelKey.tr(),
                                    style: AppTextStyles.caption.copyWith(
                                      color: widget.supportTicket.statusEnum.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.supportTicket.brokerBusinessName ?? 'Broker'} • ${widget.supportTicket.fullName}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // ── Messages Stream ───────────────────────────────────────────
                Expanded(
                  child: chatProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mark_chat_read_rounded,
                                size: 48,
                                color: AppColors.textMuted.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'no_messages_yet'.tr(),
                                style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          color: AppColors.background,
                          child: ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: messages.length + (chatProvider.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length && chatProvider.isLoadingMore) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }

                              // Reverse indexed
                              final messageIndex = messages.length - 1 - index;
                              final message = messages[messageIndex];
                              final isMe =
                                  message.senderId == currentAdminId || message.senderType == 'admin';

                              // Date separator logic
                              bool showDateSeparator = false;
                              if (messageIndex == 0) {
                                showDateSeparator = true;
                              } else {
                                final prev = messages[messageIndex - 1];
                                final currDate = message.createdAt.toLocal();
                                final prevDate = prev.createdAt.toLocal();
                                showDateSeparator =
                                    currDate.year != prevDate.year ||
                                    currDate.month != prevDate.month ||
                                    currDate.day != prevDate.day;
                              }

                              return Column(
                                children: [
                                  if (showDateSeparator) AdminChatDateSeparator(date: message.createdAt),
                                  AdminChatBubbleWidget(
                                    message: message,
                                    isMe: isMe,
                                    onReply: () {
                                      setState(() => _replyingToMessage = message);
                                    },
                                    onEdit: () => _handleEditMessage(message),
                                    onDelete: () => _handleDeleteMessage(message),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),

                // ── Input Bar ─────────────────────────────────────────────────
                AdminChatInputBarWidget(
                  isSending: chatProvider.isSending,
                  replyMessage: _replyingToMessage,
                  onCancelReply: () => setState(() => _replyingToMessage = null),
                  onSendMessage: _handleSendMessage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
