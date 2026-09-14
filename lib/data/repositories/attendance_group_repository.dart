import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attendance_group.dart';

class AttendanceGroupRepository {
  AttendanceGroupRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> createGroup({
    required String eventId,
    required String name,
    String? meetingPoint,
    double? meetingLat,
    double? meetingLng,
    DateTime? meetingTime,
  }) async {
    final result = await _client.rpc(
      'create_attendance_group',
      params: {
        'p_event_id': eventId,
        'p_name': name,
        'p_meeting_point': meetingPoint,
        'p_meeting_lat': meetingLat,
        'p_meeting_lng': meetingLng,
        'p_meeting_time': meetingTime?.toIso8601String(),
      },
    );
    if (result is Map) return result['id']?.toString() ?? '';
    return result?.toString() ?? '';
  }

  Future<AttendanceGroup?> getGroup(String groupId) async {
    final row = await _client
        .from('attendance_groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();
    return row == null ? null : AttendanceGroup.fromSupabase(row);
  }

  Future<List<AttendanceGroupMember>> getMembers(String groupId) async {
    final rows = await _client
        .from('attendance_group_members')
        .select('*, profiles:user_id(display_name, avatar_url)')
        .eq('group_id', groupId)
        .order('joined_at');
    return rows.map(AttendanceGroupMember.fromSupabase).toList(growable: false);
  }

  Future<void> inviteUser({
    required String groupId,
    required String invitedUserId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be signed in to invite a user.');
    }
    await _client.from('group_invites').insert({
      'group_id': groupId,
      'invited_by': userId,
      'invited_user': invitedUserId,
      'status': 'pending',
    });
    try {
      await _client.from('notifications').insert({
        'user_id': invitedUserId,
        'kind': 'group_invite',
        'type': 'group_invite',
        'title': 'Group invitation',
        'body': 'You have been invited to join an attendance group.',
        'read': false,
        'read_at': null,
      });
    } on PostgrestException {
      // Notification delivery may be restricted to the service role/Edge
      // Function; the invite itself remains successfully created.
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    await _client.rpc('accept_group_invite', params: {'p_invite_id': inviteId});
  }

  Future<void> declineInvite(String inviteId) async {
    await _client
        .rpc('decline_group_invite', params: {'p_invite_id': inviteId});
  }

  Future<List<GroupInvite>> getMyPendingInvites() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    final rows = await _client
        .from('group_invites')
        .select(
            '*, inviter:invited_by(display_name), invitee:invited_user(display_name), groups(name, events(title))')
        .eq('invited_user', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows.map(GroupInvite.fromSupabase).toList(growable: false);
  }

  Stream<List<GroupInvite>> watchMyPendingInvites() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const []);
    late StreamController<List<GroupInvite>> controller;
    RealtimeChannel? channel;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final invites = await getMyPendingInvites();
        if (!disposed && !controller.isClosed) controller.add(invites);
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<List<GroupInvite>>(
      onListen: () {
        refresh();
        channel =
            _client.channel('public:group_invites:$userId').onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'group_invites',
                  filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'invited_user',
                    value: userId,
                  ),
                  callback: (_) => refresh(),
                );
        channel?.subscribe();
      },
      onCancel: () async {
        disposed = true;
        if (channel != null) await _client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  Future<List<GroupMessage>> getMessages(String groupId,
      {int limit = 50}) async {
    final rows = await _client
        .from('group_messages')
        .select('*, profiles:sender_id(display_name)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(GroupMessage.fromSupabase).toList(growable: false);
  }

  Future<void> sendMessage({
    required String groupId,
    required String body,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be signed in to send a message.');
    }
    final text = body.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(body, 'body', 'Message cannot be empty.');
    }
    await _client.from('group_messages').insert({
      'group_id': groupId,
      'sender_id': userId,
      'body': text,
    });
  }

  Future<List<GroupExpense>> getExpenses(String groupId) async {
    final rows = await _client
        .from('group_expenses')
        .select('*, profiles:paid_by(display_name)')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return rows.map(GroupExpense.fromSupabase).toList(growable: false);
  }

  Future<void> addExpense({
    required String groupId,
    required String description,
    required double amount,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be signed in to add an expense.');
    }
    await _client.from('group_expenses').insert({
      'group_id': groupId,
      'paid_by': userId,
      'description': description.trim(),
      'amount': amount,
      'currency': 'USD',
    });
  }

  Future<void> leaveGroup(String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You must be signed in to leave a group.');
    }
    await _client
        .from('attendance_group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<void> deleteGroup(String groupId) async {
    await _client.from('attendance_groups').delete().eq('id', groupId);
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? meetingPoint,
    double? meetingLat,
    double? meetingLng,
    DateTime? meetingTime,
  }) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (meetingPoint != null) 'meeting_point': meetingPoint,
      if (meetingLat != null) 'meeting_lat': meetingLat,
      if (meetingLng != null) 'meeting_lng': meetingLng,
      if (meetingTime != null) 'meeting_time': meetingTime.toIso8601String(),
    };
    if (updates.isEmpty) return;
    await _client.from('attendance_groups').update(updates).eq('id', groupId);
  }

  Future<List<Map<String, dynamic>>> getGroupsForEvent(String eventId) async {
    final rows = await _client
        .from('attendance_groups')
        .select('id, name, member_count, host:created_by(display_name)')
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    return rows.map((row) {
      final host = row['host'];
      final hostMap = host is Map ? Map<String, dynamic>.from(host) : const {};
      return <String, dynamic>{
        'id': row['id'],
        'name': row['name'],
        'member_count': row['member_count'] ?? 0,
        'host_display_name': hostMap['display_name'],
      };
    }).toList(growable: false);
  }

  Future<bool> hasGroupMembershipForEvent({
    required String eventId,
    required String userId,
  }) async {
    final rows = await _client
        .from('attendance_group_members')
        .select('group_id, attendance_groups!inner(event_id)')
        .eq('user_id', userId)
        .eq('attendance_groups.event_id', eventId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Stream<List<GroupMessage>> watchMessages(String groupId) =>
      _watch(groupId, 'group_messages', getMessages);

  Stream<List<AttendanceGroupMember>> watchMembers(String groupId) =>
      _watch(groupId, 'attendance_group_members', getMembers);

  Stream<List<T>> _watch<T>(
    String groupId,
    String table,
    Future<List<T>> Function(String) loader,
  ) {
    late StreamController<List<T>> controller;
    RealtimeChannel? channel;
    var disposed = false;

    Future<void> refresh() async {
      try {
        final rows = await loader(groupId);
        if (!disposed && !controller.isClosed) controller.add(rows);
      } catch (error, stackTrace) {
        if (!disposed && !controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    Future<void> cancel() async {
      disposed = true;
      if (channel != null) {
        await _client.removeChannel(channel!);
      }
    }

    controller = StreamController<List<T>>(
      onListen: () {
        refresh();
        channel = _client.channel('public:$table:$groupId').onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'group_id',
                value: groupId,
              ),
              callback: (_) => refresh(),
            );
        channel?.subscribe();
      },
      onCancel: cancel,
    );
    return controller.stream;
  }
}
