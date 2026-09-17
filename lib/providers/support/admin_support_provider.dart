// File: lib/providers/support/admin_support_provider.dart
// Purpose: Super Admin provider for managing broker support tickets, status workflows, reopen requests, staff assignment, and real-time synchronization.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/supabase_client.dart';
import '../../models/models.dart';

class AdminSupportProvider extends ChangeNotifier {
  List<SupportTicketModel> _allTickets = [];
  List<SupportTicketModel> _filteredTickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filters & Search
  String _searchQuery = '';
  String _selectedStatusFilter = 'all'; // 'all', 'open', 'in_progress', 'reopen_requested', 'resolved', 'closed'
  SupportCategory? _selectedCategory;
  SupportTicketPriority? _selectedPriority;

  // Pagination
  int _currentPage = 1;
  int _pageSize = 10;

  // Realtime subscription
  RealtimeChannel? _subscription;
  String? _activeChatRoomId;
  String? get activeChatRoomId => _activeChatRoomId;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedStatusFilter => _selectedStatusFilter;
  SupportCategory? get selectedCategory => _selectedCategory;
  SupportTicketPriority? get selectedPriority => _selectedPriority;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  List<SupportTicketModel> get tickets => _getPaginatedTickets();
  List<SupportTicketModel> get allFilteredTickets => _filteredTickets;

  int get totalFilteredCount => _filteredTickets.length;
  int get totalPages => (_filteredTickets.isEmpty) ? 1 : (_filteredTickets.length / _pageSize).ceil();

  // Metrics
  int get totalTicketsCount => _allTickets.length;
  int get openCount => _allTickets.where((t) => t.isOpen).length;
  int get inProgressCount => _allTickets.where((t) => t.isInProgress).length;
  int get reopenRequestedCount => _allTickets.where((t) => t.reopenRequested).length;
  int get resolvedCount => _allTickets.where((t) => t.isResolved || t.isClosed).length;
  int get totalUnreadCount => _allTickets.fold(0, (sum, t) => sum + t.unreadCount);
  int get unreadTicketsCount => _allTickets.where((t) => t.unreadCount > 0).length;

  List<SupportTicketModel> _getPaginatedTickets() {
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= _filteredTickets.length) {
      return [];
    }
    final endIndex = (startIndex + _pageSize > _filteredTickets.length)
        ? _filteredTickets.length
        : startIndex + _pageSize;
    return _filteredTickets.sublist(startIndex, endIndex);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _currentPage = 1;
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    _currentPage = 1;
    _applyFilters();
  }

  void setCategoryFilter(SupportCategory? category) {
    _selectedCategory = category;
    _currentPage = 1;
    _applyFilters();
  }

  void setPriorityFilter(SupportTicketPriority? priority) {
    _selectedPriority = priority;
    _currentPage = 1;
    _applyFilters();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void setPageSize(int size) {
    _pageSize = size;
    _currentPage = 1;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStatusFilter = 'all';
    _selectedCategory = null;
    _selectedPriority = null;
    _currentPage = 1;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredTickets = _allTickets.where((ticket) {
      // Status filter
      if (_selectedStatusFilter == 'unread') {
        if (ticket.unreadCount <= 0) return false;
      } else if (_selectedStatusFilter == 'reopen_requested') {
        if (!ticket.reopenRequested) return false;
      } else if (_selectedStatusFilter != 'all') {
        if (ticket.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) return false;
      }

      // Category filter
      if (_selectedCategory != null) {
        if (ticket.categoryEnum != _selectedCategory) return false;
      }

      // Priority filter
      if (_selectedPriority != null) {
        if (ticket.priorityEnum != _selectedPriority) return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        final matchesTicketNo = ticket.ticketNumber.toLowerCase().contains(query);
        final matchesName = ticket.fullName.toLowerCase().contains(query);
        final matchesEmail = ticket.email.toLowerCase().contains(query);
        final matchesSubject = ticket.subject.toLowerCase().contains(query);
        final matchesBrokerName = (ticket.brokerBusinessName ?? '').toLowerCase().contains(query);
        final matchesBrokerCode = (ticket.brokerCode ?? '').toLowerCase().contains(query);

        if (!matchesTicketNo &&
            !matchesName &&
            !matchesEmail &&
            !matchesSubject &&
            !matchesBrokerName &&
            !matchesBrokerCode) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  /// Set the currently open chat room to suppress unread badges while actively chatting
  void setActiveChatRoom(String? roomId) {
    _activeChatRoomId = roomId;
    if (roomId != null && roomId.isNotEmpty) {
      final index = _allTickets.indexWhere((t) => t.chatRoomId == roomId);
      if (index != -1) {
        if (_allTickets[index].unreadCount > 0) {
          _allTickets[index] = _allTickets[index].copyWith(unreadCount: 0);
          _applyFilters();
        }
        markTicketAsRead(_allTickets[index].id, roomId);
      }
    }
  }

  /// Mark ticket and associated chat room as read
  Future<void> markTicketAsRead(String ticketId, String? roomId) async {
    final index = _allTickets.indexWhere((t) => t.id == ticketId);
    if (index != -1 && _allTickets[index].unreadCount > 0) {
      _allTickets[index] = _allTickets[index].copyWith(unreadCount: 0);
      _applyFilters();
    }
    if (roomId != null && roomId.isNotEmpty) {
      try {
        await SupabaseConfig.client.rpc(
          'mark_chat_room_read',
          params: {'p_room_id': roomId},
        );
      } catch (e) {
        debugPrint('[AdminSupportProvider] Error marking room read: $e');
      }
    }
  }

  /// Fetches all tickets with joined broker and chat details
  Future<void> fetchTickets({bool showLoading = true}) async {
    if (showLoading) _setLoading(true);
    _errorMessage = null;

    try {
      try {
        final rpcRes = await SupabaseConfig.client.rpc(
          'get_admin_support_tickets',
          params: {
            'p_status': null,
            'p_priority': null,
            'p_category': null,
            'p_limit': 500,
            'p_offset': 0,
          },
        );
        if (rpcRes != null && rpcRes is Map && rpcRes['tickets'] != null) {
          final rawList = rpcRes['tickets'] as List<dynamic>;
          _allTickets = rawList.map((item) => SupportTicketModel.fromJson(item)).toList();
          _applyFilters();
          subscribeToChatMessages();
          subscribeToParticipantWatermarks();
          return;
        }
      } catch (rpcErr) {
        debugPrint('[AdminSupportProvider] RPC get_admin_support_tickets fallback: $rpcErr');
      }

      dynamic response;
      try {
        response = await SupabaseConfig.client
            .from('support_tickets')
            .select('''
              *,
              broker:broker_id(business_name, broker_code),
              assigned_user:assigned_to(name),
              chat_rooms(id)
            ''')
            .eq('is_deleted', false)
            .order('created_at', ascending: false);
      } catch (joinError) {
        debugPrint('[AdminSupportProvider] Joined query failed, falling back to base select: $joinError');
        response = await SupabaseConfig.client
            .from('support_tickets')
            .select('*')
            .eq('is_deleted', false)
            .order('created_at', ascending: false);
      }

      final List<dynamic> data = response as List<dynamic>;
      _allTickets = data.map((json) => SupportTicketModel.fromJson(json)).toList();
      _applyFilters();
      subscribeToChatMessages();
      subscribeToParticipantWatermarks();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[AdminSupportProvider] Error fetching admin support tickets: $e');
    } finally {
      if (showLoading) _setLoading(false);
    }
  }

  /// Updates ticket status with automatic timestamps
  Future<bool> updateTicketStatus(
    String ticketId,
    String newStatus, {
    String? adminNotes,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': now.toIso8601String(),
      };

      if (newStatus == 'resolved') {
        updates['resolved_at'] = now.toIso8601String();
      } else if (newStatus == 'closed') {
        updates['closed_at'] = now.toIso8601String();
      } else if (newStatus == 'in_progress' || newStatus == 'open') {
        updates['resolved_at'] = null;
        updates['closed_at'] = null;
      }

      if (adminNotes != null && adminNotes.trim().isNotEmpty) {
        updates['admin_notes'] = adminNotes.trim();
      }

      await SupabaseConfig.client
          .from('support_tickets')
          .update(updates)
          .eq('id', ticketId);

      // Local optimistic update
      final index = _allTickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        final current = _allTickets[index];
        _allTickets[index] = current.copyWith(
          status: newStatus,
          adminNotes: adminNotes ?? current.adminNotes,
          resolvedAt: newStatus == 'resolved' ? now.toLocal() : (newStatus == 'open' || newStatus == 'in_progress' ? null : current.resolvedAt),
          closedAt: newStatus == 'closed' ? now.toLocal() : (newStatus == 'open' || newStatus == 'in_progress' ? null : current.closedAt),
          updatedAt: now.toLocal(),
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating ticket status: $e');
      return false;
    }
  }

  /// Updates ticket priority
  Future<bool> updateTicketPriority(String ticketId, String newPriority) async {
    try {
      final now = DateTime.now().toUtc();
      await SupabaseConfig.client
          .from('support_tickets')
          .update({
            'priority': newPriority,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', ticketId);

      final index = _allTickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _allTickets[index] = _allTickets[index].copyWith(
          priority: newPriority,
          updatedAt: now.toLocal(),
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating ticket priority: $e');
      return false;
    }
  }

  /// Assigns a ticket to an admin staff user
  Future<bool> assignTicket(String ticketId, String? adminUserId, {String? adminName}) async {
    try {
      final now = DateTime.now().toUtc();
      await SupabaseConfig.client
          .from('support_tickets')
          .update({
            'assigned_to': adminUserId,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', ticketId);

      final index = _allTickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _allTickets[index] = _allTickets[index].copyWith(
          assignedTo: adminUserId,
          assignedAdminName: adminName,
          updatedAt: now.toLocal(),
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      debugPrint('Error assigning ticket: $e');
      return false;
    }
  }

  /// Resolves or approves a reopen request
  Future<bool> resolveReopenRequest(
    String ticketId, {
    required bool approve,
    String? adminNote,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final updates = <String, dynamic>{
        'reopen_requested': false,
        'updated_at': now.toIso8601String(),
      };

      if (approve) {
        updates['status'] = 'in_progress';
        updates['resolved_at'] = null;
        updates['closed_at'] = null;
      }

      if (adminNote != null && adminNote.trim().isNotEmpty) {
        updates['admin_notes'] = adminNote.trim();
      }

      await SupabaseConfig.client
          .from('support_tickets')
          .update(updates)
          .eq('id', ticketId);

      final index = _allTickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        final current = _allTickets[index];
        _allTickets[index] = current.copyWith(
          reopenRequested: false,
          status: approve ? 'in_progress' : current.status,
          adminNotes: adminNote ?? current.adminNotes,
          resolvedAt: approve ? null : current.resolvedAt,
          closedAt: approve ? null : current.closedAt,
          updatedAt: now.toLocal(),
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      debugPrint('Error resolving reopen request: $e');
      return false;
    }
  }

  /// Updates internal admin notes
  Future<bool> updateAdminNotes(String ticketId, String notes) async {
    try {
      final now = DateTime.now().toUtc();
      await SupabaseConfig.client
          .from('support_tickets')
          .update({
            'admin_notes': notes.trim(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', ticketId);

      final index = _allTickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _allTickets[index] = _allTickets[index].copyWith(
          adminNotes: notes.trim(),
          updatedAt: now.toLocal(),
        );
        _applyFilters();
      }
      return true;
    } catch (e) {
      debugPrint('Error saving admin notes: $e');
      return false;
    }
  }

  /// Creates a ticket on behalf of a broker
  Future<bool> createTicketOnBehalfOfBroker({
    required String brokerId,
    required String fullName,
    required String email,
    String? phone,
    required String category,
    required String subject,
    required String description,
    String priority = 'normal',
  }) async {
    try {
      final currentAdminUser = SupabaseConfig.client.auth.currentUser;
      if (currentAdminUser == null) return false;

      // Get broker code
      final brokerData = await SupabaseConfig.client
          .from('brokers')
          .select('broker_code')
          .eq('id', brokerId)
          .maybeSingle();

      final brokerCode = (brokerData?['broker_code']?.toString() ?? 'BRK').toUpperCase();

      // Get next counter
      final counterResult = await SupabaseConfig.client
          .from('support_tickets')
          .select('ticket_counter')
          .eq('broker_id', brokerId)
          .order('ticket_counter', ascending: false)
          .limit(1);

      int nextCounter = 1;
      if (counterResult.isNotEmpty) {
        nextCounter = (int.tryParse(counterResult[0]['ticket_counter']?.toString() ?? '0') ?? 0) + 1;
      }

      final ticketNumber = 'TKT-$brokerCode-${nextCounter.toString().padLeft(3, '0')}';

      final ticketResponse = await SupabaseConfig.client
          .from('support_tickets')
          .insert({
            'ticket_number': ticketNumber,
            'ticket_counter': nextCounter,
            'broker_id': brokerId,
            'user_id': currentAdminUser.id,
            'full_name': fullName.trim(),
            'email': email.trim(),
            'phone': phone?.trim().isNotEmpty == true ? phone!.trim() : null,
            'category': category.trim(),
            'subject': subject.trim(),
            'description': description.trim(),
            'status': 'open',
            'priority': priority,
            'attachments': [],
          })
          .select()
          .single();

      final ticketId = ticketResponse['id']?.toString() ?? '';

      // Create chat room
      final roomResponse = await SupabaseConfig.client
          .from('chat_rooms')
          .insert({
            'support_ticket_id': ticketId,
            'broker_id': brokerId,
            'room_type': 'support_ticket',
          })
          .select()
          .single();

      final roomId = roomResponse['id']?.toString() ?? '';

      // Insert initial message
      await SupabaseConfig.client.from('chat_messages').insert({
        'room_id': roomId,
        'sender_id': currentAdminUser.id,
        'sender_type': 'admin',
        'message': description.trim(),
        'message_type': 'text',
        'medias': [],
      });

      await fetchTickets(showLoading: false);
      return true;
    } catch (e) {
      debugPrint('Error creating ticket on behalf of broker: $e');
      return false;
    }
  }

  /// Real-time subscription to support_tickets table
  void subscribeToChanges() {
    _subscription?.unsubscribe();
    _subscription = SupabaseConfig.client
        .channel('public:support_tickets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_tickets',
          callback: (payload) {
            fetchTickets(showLoading: false);
          },
        )
        .subscribe();
  }

  RealtimeChannel? _chatMessagesSubscription;
  RealtimeChannel? _participantsSubscription;

  /// Subscribe to chat messages across tickets for live unread updates
  void subscribeToChatMessages() {
    if (_chatMessagesSubscription != null) return;

    _chatMessagesSubscription = SupabaseConfig.client
        .channel('admin_support_tickets_chat')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final newJson = payload.newRecord;
            if (newJson.isNotEmpty && newJson['is_deleted'] != true) {
              final roomId = newJson['room_id']?.toString();
              final senderId = newJson['sender_id']?.toString();
              final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
              if (roomId != null && senderId != currentUserId) {
                final idx = _allTickets.indexWhere((t) => t.chatRoomId == roomId);
                if (idx != -1) {
                  final ticket = _allTickets[idx];
                  final isRoomActive = roomId == _activeChatRoomId;
                  final newUnread = isRoomActive ? 0 : ticket.unreadCount + 1;
                  _allTickets[idx] = ticket.copyWith(
                    unreadCount: newUnread,
                    lastMessage: newJson['message']?.toString(),
                    lastMessageAt: DateTime.tryParse(newJson['created_at']?.toString() ?? '')?.toLocal(),
                  );
                  _applyFilters();
                }
              }
            }
          },
        );

    _chatMessagesSubscription!.subscribe();
  }

  /// Subscribe to participant updates to instantly zero out unread count when marked as read
  void subscribeToParticipantWatermarks() {
    if (_participantsSubscription != null) return;
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _participantsSubscription = SupabaseConfig.client
        .channel('admin_chat_participants_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_room_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final rec = payload.newRecord;
            if (rec.isNotEmpty) {
              final roomId = rec['room_id']?.toString();
              if (roomId != null) {
                final idx = _allTickets.indexWhere((t) => t.chatRoomId == roomId);
                if (idx != -1 && _allTickets[idx].unreadCount > 0) {
                  _allTickets[idx] = _allTickets[idx].copyWith(unreadCount: 0);
                  _applyFilters();
                }
              }
            }
          },
        );

    _participantsSubscription!.subscribe();
  }

  void unsubscribe() {
    _subscription?.unsubscribe();
    _subscription = null;
    _chatMessagesSubscription?.unsubscribe();
    _chatMessagesSubscription = null;
    _participantsSubscription?.unsubscribe();
    _participantsSubscription = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
