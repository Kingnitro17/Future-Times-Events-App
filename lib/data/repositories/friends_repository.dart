import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsRepository {
  FriendsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    final response = await _client
        .from('user_follows')
        .select(
          'following_id, profiles!user_follows_following_id_fkey(id, display_name, avatar_url, city)',
        )
        .eq('follower_id', userId)
        .eq('target_type', 'user');

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map((row) {
      final profile = row['profiles'] is Map ? row['profiles'] as Map<String, dynamic> : const <String, dynamic>{};
      final personId = row['following_id']?.toString() ?? '';
      return {
        'id': personId,
        'display_name': profile['display_name']?.toString() ?? 'User',
        'avatar_url': profile['avatar_url']?.toString(),
        'city': profile['city']?.toString(),
        'is_mutual': false,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    final response = await _client
        .from('user_follows')
        .select(
          'follower_id, profiles!user_follows_follower_id_fkey(id, display_name, avatar_url, city)',
        )
        .eq('following_id', userId)
        .eq('target_type', 'user');

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map((row) {
      final profile = row['profiles'] is Map ? row['profiles'] as Map<String, dynamic> : const <String, dynamic>{};
      final personId = row['follower_id']?.toString() ?? '';
      return {
        'id': personId,
        'display_name': profile['display_name']?.toString() ?? 'User',
        'avatar_url': profile['avatar_url']?.toString(),
        'city': profile['city']?.toString(),
        'is_mutual': false,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final following = await getFollowing(userId);
    final followers = await getFollowers(userId);
    final followerIds = followers.map((person) => person['id']?.toString() ?? '').toSet();
    return following
        .where((person) => followerIds.contains(person['id']?.toString() ?? ''))
        .map((person) => {
              ...person,
              'is_mutual': true,
            })
        .toList();
  }

  Future<bool> isFriend({required String userId, required String otherId}) async {
    if (userId == otherId) return false;
    final following = await getFollowing(userId);
    final followerIds = (await getFollowers(userId)).map((person) => person['id']?.toString() ?? '').toSet();
    final userFollowsOther = following.any((person) => person['id']?.toString() == otherId);
    return userFollowsOther && followerIds.contains(otherId);
  }

  Future<void> follow({required String targetId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in required to follow someone.');
    }
    await _client.from('user_follows').upsert({
      'follower_id': userId,
      'following_id': targetId,
      'target_type': 'user',
    }, onConflict: 'follower_id,following_id,target_type');
  }

  Future<void> unfollow({required String targetId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in required to unfollow someone.');
    }
    await _client
        .from('user_follows')
        .delete()
        .eq('follower_id', userId)
        .eq('following_id', targetId)
        .eq('target_type', 'user');
  }

  Stream<List<Map<String, dynamic>>> watchFriends(String userId) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    final channel = _client.channel('friends:$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'user_follows',
      callback: (_) async {
        try {
          final friends = await getFriends(userId);
          if (!controller.isClosed) {
            controller.add(friends);
          }
        } catch (_) {
          // Best-effort realtime sync; full refresh occurs on next action.
        }
      },
    );

    channel.subscribe();
    getFriends(userId).then((friends) {
      if (!controller.isClosed) {
        controller.add(friends);
      }
    });

    return controller.stream;
  }
}
