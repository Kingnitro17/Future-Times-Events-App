class SocialStats {
  const SocialStats({
    this.eventsAttended = 0,
    this.followingCount = 0,
    this.followersCount = 0,
  });

  final int eventsAttended;
  final int followingCount;
  final int followersCount;

  factory SocialStats.fromJson(Map<String, dynamic> json) {
    return SocialStats(
      eventsAttended:
          int.tryParse(json['events_attended']?.toString() ?? '0') ?? 0,
      followingCount:
          int.tryParse(json['following_count']?.toString() ?? '0') ?? 0,
      followersCount:
          int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class EventSocialSummary {
  const EventSocialSummary({
    this.goingCount = 0,
    this.friendCount = 0,
    this.friendAvatars = const [],
    this.publicAvatars = const [],
  });

  final int goingCount;
  final int friendCount;
  final List<String> friendAvatars;
  final List<String> publicAvatars;

  factory EventSocialSummary.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
      return const [];
    }

    return EventSocialSummary(
      goingCount: int.tryParse(json['going_count']?.toString() ?? '0') ?? 0,
      friendCount: int.tryParse(json['friend_count']?.toString() ?? '0') ?? 0,
      friendAvatars: parseList(json['friend_avatars']),
      publicAvatars: parseList(json['public_avatars']),
    );
  }
}

class OrganizerModel {
  const OrganizerModel({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.location,
    this.isVerified = false,
    this.followersCount = 0,
    this.isFollowing = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? location;
  final bool isVerified;
  final int followersCount;
  final bool isFollowing;

  factory OrganizerModel.fromJson(Map<String, dynamic> json) {
    return OrganizerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['organization_name']?.toString() ??
          'Organizer',
      description: json['description']?.toString(),
      logoUrl: json['logo_url']?.toString() ?? json['avatar_url']?.toString(),
      location: json['location']?.toString() ?? json['city']?.toString(),
      isVerified: json['is_verified'] == true || json['verified'] == true,
      followersCount:
          int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
      isFollowing: json['is_following'] == true,
    );
  }
}

class UserProfileCard {
  const UserProfileCard({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.isFollowing = false,
    this.isFriend = false,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isFollowing;
  final bool isFriend;

  factory UserProfileCard.fromJson(Map<String, dynamic> json) {
    return UserProfileCard(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ??
          json['name']?.toString() ??
          'User',
      avatarUrl: json['avatar_url']?.toString(),
      isFollowing: json['is_following'] == true,
      isFriend: json['is_friend'] == true,
    );
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.eventId,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? type;
  final String? eventId;
  final bool read;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ??
          json['heading']?.toString() ??
          'Notification',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      type: json['type']?.toString(),
      eventId: json['event_id']?.toString(),
      read: json['read'] == true || json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
