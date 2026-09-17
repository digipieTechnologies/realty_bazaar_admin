// File: lib/providers/chat/admin_chat_provider.dart
// Purpose: Super Admin Chat provider for 1-on-1 support chat with brokers, real-time message streaming, attachments, replies, and edits.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/supabase_client.dart';
import '../../core/services/r2_storage_service.dart';
import '../../models/models.dart';

class AdminChatProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSending = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _limit = 25;

  ChatRoomModel? _currentRoom;
  List<ChatMessageModel> _messages = [];
  ChatMessageModel? _editingMessage;
  RealtimeChannel? _chatSubscription;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  ChatRoomModel? get currentRoom => _currentRoom;
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  ChatMessageModel? get editingMessage => _editingMessage;
  String? get errorMessage => _errorMessage;

  void setEditingMessage(ChatMessageModel? message) {
    if (message != null &&
        (message.messageType != ChatMessageMessageType.text ||
            message.medias.isNotEmpty ||
            message.locationData != null)) {
      return;
    }
    _editingMessage = message;
    notifyListeners();
  }

  /// Initialize chat room for a specific support ticket ID
  Future<void> initSupportChatRoom({required String supportTicketId, String? brokerId}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentRoom = null;
    _messages = [];
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.rpc(
        'get_or_create_support_chat_room',
        params: {'p_support_ticket_id': supportTicketId},
      );

      if (response != null && response is Map<String, dynamic>) {
        _currentRoom = ChatRoomModel.fromJson(response);
        await fetchMessages(_currentRoom!.id);
        subscribeToRealtimeMessages(_currentRoom!.id);
        markRoomAsRead(_currentRoom!.id);
      } else {
        _errorMessage = 'Could not load support chat room.';
      }
    } catch (e) {
      debugPrint('[AdminChatProvider] Error initializing chat room: $e');
      _errorMessage = 'Error loading support chat room.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resolveReplyMessages(List<ChatMessageModel> list) {
    final Map<String, ChatMessageModel> map = {for (var m in list) m.id: m};
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item.replyMessageId != null && item.replyMessage == null) {
        final parent = map[item.replyMessageId];
        if (parent != null) {
          list[i] = item.copyWith(replyMessage: parent);
        }
      }
    }
  }

  /// Fetch initial latest 25 messages
  Future<void> fetchMessages(String roomId) async {
    try {
      _hasMore = true;
      _isLoadingMore = false;

      final response = await SupabaseConfig.client
          .from('chat_messages')
          .select('*')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(0, _limit - 1);

      final listData = response as List;
      final fetchedMessages = listData.map((json) => ChatMessageModel.fromJson(json)).toList().reversed.toList();

      _messages = fetchedMessages;
      _resolveReplyMessages(_messages);
      if (listData.length < _limit) {
        _hasMore = false;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminChatProvider] Error fetching chat messages: $e');
    }
  }

  /// Fetch next page of older messages
  Future<void> fetchMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _currentRoom == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final currentOffset = _messages.length;
      final response = await SupabaseConfig.client
          .from('chat_messages')
          .select('*')
          .eq('room_id', _currentRoom!.id)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(currentOffset, currentOffset + _limit - 1);

      final listData = response as List;
      final olderMessages = listData.map((json) => ChatMessageModel.fromJson(json)).toList().reversed.toList();

      if (olderMessages.isNotEmpty) {
        _messages.insertAll(0, olderMessages);
        _resolveReplyMessages(_messages);
      }

      if (listData.length < _limit) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('[AdminChatProvider] Error fetching older chat messages: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Soft-delete message
  Future<bool> deleteMessage(String messageId) async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await SupabaseConfig.client
          .from('chat_messages')
          .update({'is_deleted': true, 'deleted_at': nowUtc, 'updated_at': nowUtc})
          .eq('id', messageId);

      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AdminChatProvider] Error deleting message: $e');
      return false;
    }
  }

  /// Edit message text
  Future<bool> editMessage(String messageId, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return false;

    _editingMessage = null;
    notifyListeners();

    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      await SupabaseConfig.client
          .from('chat_messages')
          .update({'message': trimmed, 'is_edited': true, 'updated_at': nowUtc})
          .eq('id', messageId);

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          message: trimmed,
          isEdited: true,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('[AdminChatProvider] Error editing message: $e');
      return false;
    }
  }

  Future<String?> _uploadChatMedia(String localPath, {Uint8List? fileBytes}) async {
    return await R2StorageService.uploadFile(
      filePath: localPath,
      entityType: 'chat',
      entityId: _currentRoom?.id,
      fileBytes: fileBytes,
    );
  }

  /// Send message as admin
  Future<bool> sendMessage({
    required String senderId,
    required String message,
    ChatMessageMessageType messageType = ChatMessageMessageType.text,
    List<MediaModel> attachmentMedias = const [],
    String? replyMessageId,
  }) async {
    if (_currentRoom == null || (message.trim().isEmpty && attachmentMedias.isEmpty)) {
      return false;
    }

    _isSending = true;
    notifyListeners();

    try {
      List<MediaModel> uploadedMedias = [];
      if (attachmentMedias.isNotEmpty) {
        for (final item in attachmentMedias) {
          String? uploadedUrl;
          String? uploadedThumb;

          if (item.url != null && item.url!.isNotEmpty) {
            uploadedUrl = await _uploadChatMedia(item.url!);
          }

          if (item.thumbnailBytes != null && item.thumbnailBytes!.isNotEmpty) {
            final thumbName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
            uploadedThumb = await _uploadChatMedia(thumbName, fileBytes: item.thumbnailBytes);
          }

          uploadedMedias.add(item.copyWith(
            url: uploadedUrl ?? item.url,
            thumbnail: uploadedThumb ?? item.thumbnail,
          ));
        }
      }

      ChatMessageMessageType effectiveMessageType = messageType;
      if (uploadedMedias.isNotEmpty) {
        effectiveMessageType = ChatMessageMessageType.document;
      }

      final payload = {
        'room_id': _currentRoom!.id,
        'sender_id': senderId,
        'sender_type': 'admin',
        'message': message.trim(),
        'message_type': effectiveMessageType.dbValue,
        'medias': uploadedMedias.map((m) => m.toJson()).toList(),
        'reply_message_id': replyMessageId,
        'is_edited': false,
        'is_deleted': false,
      };

      final response = await SupabaseConfig.client
          .from('chat_messages')
          .insert(payload)
          .select('*')
          .single();

      var newMessage = ChatMessageModel.fromJson(response);
      if (newMessage.replyMessageId != null && newMessage.replyMessage == null) {
        final parentIndex = _messages.indexWhere((m) => m.id == newMessage.replyMessageId);
        if (parentIndex != -1) {
          newMessage = newMessage.copyWith(replyMessage: _messages[parentIndex]);
        }
      }

      if (!_messages.any((m) => m.id == newMessage.id)) {
        _messages.add(newMessage);
      }

      markRoomAsRead(_currentRoom!.id);

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AdminChatProvider] Error sending message: $e');
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  /// Subscribe to live postgres changes
  void subscribeToRealtimeMessages(String roomId) {
    _chatSubscription?.unsubscribe();

    _chatSubscription = SupabaseConfig.client
        .channel('chat_room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              final newJson = payload.newRecord;
              if (newJson.isNotEmpty && newJson['is_deleted'] != true) {
                var newMessage = ChatMessageModel.fromJson(newJson);
                if (newMessage.replyMessageId != null && newMessage.replyMessage == null) {
                  final parent = _messages.where((m) => m.id == newMessage.replyMessageId).firstOrNull;
                  if (parent != null) {
                    newMessage = newMessage.copyWith(replyMessage: parent);
                  }
                }
                if (!_messages.any((m) => m.id == newMessage.id)) {
                  _messages.add(newMessage);
                  notifyListeners();
                  markRoomAsRead(roomId);
                }
              }
            } else if (payload.eventType == PostgresChangeEvent.update) {
              final updatedJson = payload.newRecord;
              final msgId = updatedJson['id']?.toString();
              if (msgId != null) {
                if (updatedJson['is_deleted'] == true) {
                  _messages.removeWhere((m) => m.id == msgId);
                  notifyListeners();
                } else {
                  final index = _messages.indexWhere((m) => m.id == msgId);
                  if (index != -1) {
                    _messages[index] = ChatMessageModel.fromJson(updatedJson);
                    _resolveReplyMessages(_messages);
                    notifyListeners();
                  }
                }
              }
            }
          },
        )
        .subscribe();
  }

  /// Mark current chat room as read in chat_room_participants
  Future<void> markRoomAsRead([String? roomId]) async {
    final targetRoomId = roomId ?? _currentRoom?.id;
    if (targetRoomId == null || targetRoomId.isEmpty) return;
    try {
      await SupabaseConfig.client.rpc(
        'mark_chat_room_read',
        params: {'p_room_id': targetRoomId},
      );
    } catch (e) {
      debugPrint('[AdminChatProvider] Error marking room as read: $e');
    }
  }

  void closeRoom() {
    _chatSubscription?.unsubscribe();
    _chatSubscription = null;
    _currentRoom = null;
    _messages = [];
    _editingMessage = null;
  }

  @override
  void dispose() {
    closeRoom();
    super.dispose();
  }
}
