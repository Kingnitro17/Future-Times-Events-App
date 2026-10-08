import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event_message.dart';
import 'auth_repository.dart';

class EventChatRepository {
  EventChatRepository({
    required AuthRepository authRepository,
    SupabaseClient? client,
  })  : _auth = authRepository,
        _client = client ?? Supabase.instance.client;

  final AuthRepository _auth;
  final SupabaseClient _client;

  Future<List<EventMessage>> getMessages({
    required String eventId,
    int limit = 50,
    DateTime? before,
  }) async {
    final query = _client
        .from('event_messages')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false)
        .limit(limit);

    final response = await query;
    final rows = List<Map<String, dynamic>>.from(response);
    if (rows.isEmpty) return const [];

    final filteredRows = before == null
        ? rows
        : rows.where((row) {
            final value = row['created_at'];
            if (value == null) return false;
            final createdAt = DateTime.tryParse(value.toString());
            return createdAt != null && createdAt.isBefore(before.toUtc());
          }).toList();

    final resultRows = before == null ? rows : filteredRows;

    final senderIds = resultRows
        .map((row) => row['sender_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    final profiles = <String, Map<String, dynamic>>{};
    if (senderIds.isNotEmpty) {
      final profileRows = await _client
          .from('profiles')
          .select('id, display_name, avatar_url')
          .inFilter('id', senderIds);
      final profileList = List<Map<String, dynamic>>.from(profileRows);
      for (final profile in profileList) {
        final id = profile['id']?.toString();
        if (id != null && id.isNotEmpty) {
          profiles[id] = profile;
        }
      }
    }
    final currentUserId = _auth.user?.id;
    return resultRows
        .map((row) {
          final senderId = row['sender_id']?.toString() ?? '';
          final sender = profiles[senderId] ?? const <String, dynamic>{};
          final merged = <String, dynamic>{
            ...row,
            'sender': sender,
            'sender_display_name': sender['display_name'] ?? row['sender_display_name'],
            'sender_avatar_url': sender['avatar_url'] ?? row['sender_avatar_url'],
          };
          return EventMessage.fromSupabase(merged, currentUserId: currentUserId);
        })
        .toList();
  }

  Future<EventMessage> sendText({
    required String eventId,
    required String body,
  }) async {
    final userId = _auth.user?.id;
    if (userId == null) {
      throw StateError('Sign in required to send a chat message.');
    }

    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw StateError('Message cannot be empty.');
    }

    final response = await _client
        .from('event_messages')
        .insert({
          'event_id': eventId,
          'sender_id': userId,
          'kind': 'text',
          'body': trimmed,
        })
        .select()
        .single();

    final Map<String, dynamic> row = response;
    return EventMessage.fromSupabase(row, currentUserId: userId);
  }

  Future<EventMessage> sendSticker({
    required String eventId,
    required String stickerId,
  }) async {
    final userId = _auth.user?.id;
    if (userId == null) {
      throw StateError('Sign in required to send a sticker.');
    }

    final response = await _client
        .from('event_messages')
        .insert({
          'event_id': eventId,
          'sender_id': userId,
          'kind': 'sticker',
          'sticker_id': stickerId,
          'body': stickerId,
        })
        .select()
        .single();

    final Map<String, dynamic> row = response;
    return EventMessage.fromSupabase(row, currentUserId: userId);
  }

  Future<EventMessage> sendImage({
    required String eventId,
    required File file,
  }) async {
    final userId = _auth.user?.id;
    if (userId == null) {
      throw StateError('Sign in required to send an image.');
    }

    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final bytes = await file.readAsBytes();
    await _client.storage.from('event_chat').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    final publicUrl = _client.storage.from('event_chat').getPublicUrl(fileName);
    final response = await _client
        .from('event_messages')
        .insert({
          'event_id': eventId,
          'sender_id': userId,
          'kind': 'image',
          'media_url': publicUrl,
        })
        .select()
        .single();

    final Map<String, dynamic> row = response;
    return EventMessage.fromSupabase(row, currentUserId: userId);
  }

  Future<void> reactToMessage({
    required String messageId,
    required String emoji,
  }) async {
    final userId = _auth.user?.id;
    if (userId == null) {
      throw StateError('Sign in required to react to messages.');
    }

    await _client.from('event_message_reactions').upsert({
      'message_id': messageId,
      'user_id': userId,
      'emoji': emoji,
    });
  }

  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userId = _auth.user?.id;
    if (userId == null) {
      return;
    }

    await _client
        .from('event_message_reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('emoji', emoji);
  }

  Stream<List<EventMessage>> watchMessages(String eventId) {
    final controller = StreamController<List<EventMessage>>.broadcast();
    final channel = _client.channel('event_chat:$eventId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'event_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'event_id',
        value: eventId,
      ),
      callback: (_) async {
        try {
          final messages = await getMessages(eventId: eventId);
          if (!controller.isClosed) {
            controller.add(messages);
          }
        } catch (_) {
          // Best-effort realtime refresh; the stream will rehydrate on next poll.
        }
      },
    );

    channel.subscribe();
    getMessages(eventId: eventId).then((messages) {
      if (!controller.isClosed) controller.add(messages);
    });

    return controller.stream;
  }

  Future<void> deleteMessage(String messageId) async {
    final userId = _auth.user?.id;
    if (userId == null) {
      throw StateError('Sign in required to delete a message.');
    }

    await _client
        .from('event_messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', userId);
  }
}
