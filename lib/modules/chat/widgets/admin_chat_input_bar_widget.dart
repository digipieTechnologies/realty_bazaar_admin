// File: lib/modules/chat/widgets/admin_chat_input_bar_widget.dart
// Purpose: Self-contained chat input bar for admin chat supporting file attachments, reply preview, and quick send.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../widgets/toast/app_toast.dart';

class AdminChatInputBarWidget extends StatefulWidget {
  final bool isSending;
  final ChatMessageModel? replyMessage;
  final VoidCallback? onCancelReply;
  final Future<void> Function({
    required String text,
    List<MediaModel> attachments,
  }) onSendMessage;

  const AdminChatInputBarWidget({
    super.key,
    required this.isSending,
    this.replyMessage,
    this.onCancelReply,
    required this.onSendMessage,
  });

  @override
  State<AdminChatInputBarWidget> createState() => _AdminChatInputBarWidgetState();
}

class _AdminChatInputBarWidgetState extends State<AdminChatInputBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<MediaModel> _selectedAttachments = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          final bytes = file.bytes;
          final path = file.path ?? file.name;
          final isImage = ['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase());

          _selectedAttachments.add(MediaModel(
            type: isImage ? 'image' : 'document',
            url: path,
            bytes: bytes,
            thumbnailBytes: isImage ? bytes : null,
          ));
        }
        setState(() {});
      }
    } catch (e) {
      AppToast.showError('Could not pick files: $e');
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedAttachments.isEmpty) return;

    final attachmentsCopy = List<MediaModel>.from(_selectedAttachments);
    _controller.clear();
    setState(() {
      _selectedAttachments.clear();
    });

    widget.onSendMessage(
      text: text,
      attachments: attachmentsCopy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Replying Banner ─────────────────────────────────────────────
          if (widget.replyMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(8),
                border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${widget.replyMessage?.senderType == 'admin' ? 'You' : 'Broker'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.replyMessage?.message ?? 'Attachment',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: widget.onCancelReply,
                  ),
                ],
              ),
            ),
          ],

          // ── Attachments Preview Chips ───────────────────────────────────
          if (_selectedAttachments.isNotEmpty) ...[
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedAttachments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, index) {
                  final att = _selectedAttachments[index];
                  final name = att.url?.split('/').last.split('\\').last ?? 'File';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          att.type == 'image' ? Icons.image_rounded : Icons.attach_file_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedAttachments.removeAt(index));
                          },
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary700),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Input Row ───────────────────────────────────────────────────
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file_rounded, color: AppColors.iconDefault),
                tooltip: 'Attach Files',
                onPressed: widget.isSending ? null : _pickFiles,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      _submit();
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    enabled: !widget.isSending,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Type your message to the broker...',
                      hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: widget.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: widget.isSending ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
