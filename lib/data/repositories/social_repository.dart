import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendee_model.dart';
import '../models/social_models.dart';

class SocialRepository {
  SocialRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final Map<String, EventSocialSummary> _summaryCache = {};

  /// Fetch social stats for the current signed-in user
  Future<SocialStats> getSocialStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const SocialStats();
    try {
      final res = await _client.rpc('get_my_social_stats');
      if (res is Map<String, dynamic>) {
        return SocialStats.fromJson(res);
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) debugPrint('[social] get_my_social_stats RPC failed: $e');
    } catch (e) {
      if (kDebugMode) debugPrint('[social] stats error: $e');
    }
    // Fallback: direct table queries if RPC unavailable
    try {
      final followsCount = await _client
          .from('user_follows')
          .select('id')
          .eq('follower_id', userId);
      final followersCount = await _client
          .from('user_follows')
          .select('id')
          .eq('following_id', userId);
      final rsvpsCount = await _client
          .from('rsvps')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'going');
      return SocialStats(
        eventsAttended: (rsvpsCount as List).length,
        followingCount: (followsCount as List).length,
        followersCount: (followersCount as List).length,
      );
    } catch (_) {
      return const SocialStats();
    }
  }

  /// Get event social summary for home cards and details screen using get_event_social_summary RPC
  Future<EventSocialSummary> getEventSocialSummary(String eventId) async {
    if (_summaryCache.containsKey(eventId)) {
      return _summaryCache[eventId]!;
    }
    try {
      final res = await _client.rpc(
        'get_event_social_summary',
        params: {'p_event_id': eventId},
      );
      if (res is Map<String, dynamic>) {
        final summary = EventSocialSummary.fromJson(res);
        _summaryCache[eventId] = summary;
        return summary;
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('[social] get_event_social_summary failed: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[social] summary error: $e');
      }
    }

    return const EventSocialSummary();
  }

  /// Get visible attendees for Who's Going sheet using get_event_visible_attendees RPC
  Future<List<AttendeeModel>> getEventVisibleAttendees(
    String eventId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await _client.rpc(
        'get_event_visible_attendees',
        params: {
          'p_event_id': eventId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      if (res is List) {
        return res.map((row) {
          final map = row as Map<String, dynamic>;
          return AttendeeModel(
            userId: map['user_id']?.toString() ?? '',
            eventId: eventId,
            displayName: map['display_name']?.toString() ?? 'Attendee',
            avatarUrl: map['avatar_url']?.toString(),
            checkedInAt: DateTime.tryParse(map['rsvp_at']?.toString() ?? ''),
            isFriend: map['is_friend'] == true || map['is_following'] == true,
          );
        }).toList();
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('[social] get_event_visible_attendees failed: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[social] visible attendees error: $e');
      }
    }

    return const [];
  }

  /// Legacy helper — delegates to [getEventVisibleAttendees]
  Future<List<AttendeeModel>> getAttendees(String eventId) =>
      getEventVisibleAttendees(eventId);

  /// Check if user has RSVPed 'going' to an event
  Future<bool> hasRSVPed(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await _client
          .from('rsvps')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .eq('status', 'going')
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  /// RSVP to an event
  Future<void> setRSVP({
    required String eventId,
    required bool going,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Authentication required to RSVP.');
    }
    _summaryCache.remove(eventId);
    if (going) {
      await _client.from('rsvps').upsert({
        'event_id': eventId,
        'user_id': userId,
        'status': 'going',
        'is_public': true,
      }, onConflict: 'event_id,user_id');
    } else {
      await _client
          .from('rsvps')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
    }
  }

  /// Follow a user
  Future<void> followUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Sign in required.');
    await _client.from('user_follows').upsert({
      'follower_id': userId,
      'following_id': targetUserId,
    }, onConflict: 'follower_id,following_id');
  }

  /// Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('user_follows')
        .delete()
        .eq('follower_id', userId)
        .eq('following_id', targetUserId);
  }

  /// Get list of organizers followed by current user
  Future<List<OrganizerModel>> getFollowingOrganizers() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final res = await _client.rpc('get_my_following_organizers');
      if (res is List) {
        return res
            .map((row) => OrganizerModel.fromJson(row as Map<String, dynamic>))
            .toList();
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('[social] get_my_following_organizers failed: $e');
      }
    } catch (_) {}
    return const [];
  }

  /// Fetch popular/curated organizers
  Future<List<OrganizerModel>> getAllOrganizers() async {
    final userId = _client.auth.currentUser?.id;
    try {
      final rows = await _client
          .from('organizer_profiles')
          .select('*, profiles(display_name, avatar_url, city)')
          .limit(30);
      final list = rows as List;
      final followingSet = <String>{};
      if (userId != null) {
        final follows = await _client
            .from('user_follows')
            .select('following_id')
            .eq('follower_id', userId) as List;
        for (final f in follows) {
          followingSet.add(f['following_id'].toString());
        }
      }
      return list.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final orgId = map['id']?.toString() ?? '';
        map['is_following'] = followingSet.contains(orgId);
        return OrganizerModel.fromJson(map);
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[social] getAllOrganizers failed: $e');
    }
    return const [];
  }

  /// Get list of users the current user is following
  Future<List<UserProfileCard>> getFollowing() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final rows = await _client
          .from('user_follows')
          .select(
              'following_id, profiles!user_follows_following_id_fkey(display_name, avatar_url)')
          .eq('follower_id', userId);
      final list = rows as List;
      return list.map((row) {
        final profile = row['profiles'] as Map<String, dynamic>? ?? {};
        return UserProfileCard(
          userId: row['following_id'].toString(),
          displayName: profile['display_name']?.toString() ?? 'User',
          avatarUrl: profile['avatar_url']?.toString(),
          isFollowing: true,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[social] getFollowing failed: $e');
    }
    return const [];
  }

  /// Get list of followers for current user
  Future<List<UserProfileCard>> getFollowers() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final rows = await _client
          .from('user_follows')
          .select(
              'follower_id, profiles!user_follows_follower_id_fkey(display_name, avatar_url)')
          .eq('following_id', userId);
      final list = rows as List;
      return list.map((row) {
        final profile = row['profiles'] as Map<String, dynamic>? ?? {};
        return UserProfileCard(
          userId: row['follower_id'].toString(),
          displayName: profile['display_name']?.toString() ?? 'User',
          avatarUrl: profile['avatar_url']?.toString(),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[social] getFollowers failed: $e');
    }
    return const [];
  }

  /// Get mutual friends (users where both follow each other)
  Future<List<UserProfileCard>> getFriends() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];
    try {
      final following = await getFollowing();
      final followers = await getFollowers();
      final followerIds = followers.map((f) => f.userId).toSet();
      return following
          .where((f) => followerIds.contains(f.userId))
          .map((f) => UserProfileCard(
                userId: f.userId,
                displayName: f.displayName,
                avatarUrl: f.avatarUrl,
                isFollowing: true,
                isFriend: true,
              ))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[social] getFriends failed: $e');
    }
    return const [];
  }

  /// Search users by display name
  Future<List<UserProfileCard>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final rows = await _client
          .from('profiles')
          .select('id, display_name, avatar_url')
          .ilike('display_name', '%$trimmed%')
          .limit(25);
      final list = rows as List;
      final userId = _client.auth.currentUser?.id;
      final followingSet = <String>{};
      if (userId != null) {
        final follows = await _client
            .from('user_follows')
            .select('following_id')
            .eq('follower_id', userId) as List;
        for (final f in follows) {
          followingSet.add(f['following_id'].toString());
        }
      }
      return list.map((row) {
        final id = row['id'].toString();
        return UserProfileCard(
          userId: id,
          displayName: row['display_name']?.toString() ?? 'User',
          avatarUrl: row['avatar_url']?.toString(),
          isFollowing: followingSet.contains(id),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[social] searchUsers failed: $e');
    }
    return const [];
  }

  // ── Backward-compatible aliases used by SocialBloc & DetailsScreen ──────────

  /// Alias for [setRSVP(going: true)] — used by existing SocialBloc
  Future<void> checkIn({
    required String eventId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) =>
      setRSVP(eventId: eventId, going: true);

  /// Alias for [setRSVP(going: false)] — used by existing SocialBloc
  Future<void> checkOut({
    required String eventId,
    required String userId,
  }) =>
      setRSVP(eventId: eventId, going: false);

  /// Alias for [hasRSVPed] — used by DetailsScreen
  Future<bool> hasCheckedIn({
    required String eventId,
    required String userId,
  }) =>
      hasRSVPed(eventId);

  /// Total going count — used by SocialBloc
  Future<int> getAttendeeCount(String eventId) async {
    final summary = await getEventSocialSummary(eventId);
    return summary.goingCount;
  }

  /// Stream wrapper for legacy BLoC compatibility
  Stream<List<AttendeeModel>> watchAttendees(String eventId) =>
      Stream.fromFuture(getAttendees(eventId));

  /// Stream wrapper for legacy BLoC compatibility
  Stream<int> watchAttendeeCount(String eventId) =>
      Stream.fromFuture(getAttendeeCount(eventId));
}
