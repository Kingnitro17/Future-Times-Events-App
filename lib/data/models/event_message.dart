class EventMessage {
  const EventMessage({
    required this.id,
    required this.eventId,
    required this.senderId,
    required this.kind,
    this.body,
    this.mediaUrl,
    this.stickerId,
    required this.createdAt,
    this.senderDisplayName,
    this.senderAvatarUrl,
    this.reactionCounts = const {},
    this.myReactions = const [],
  });

  final String id;
  final String eventId;
  final String senderId;
  final String kind;
  final String? body;
  final String? mediaUrl;
  final String? stickerId;
  final DateTime createdAt;
  final String? senderDisplayName;
  final String? senderAvatarUrl;
  final Map<String, int> reactionCounts;
  final List<String> myReactions;

  factory EventMessage.fromSupabase(
    Map<String, dynamic> row, {
    String? currentUserId,
  }) {
    final rawCounts = row['reaction_counts'];
    final reactionCounts = <String, int>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        reactionCounts[key] = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
      }
    }

    final myReactions = <String>[];
    final rawMyReactions = row['my_reactions'];
    if (rawMyReactions is List) {
      for (final item in rawMyReactions) {
        final value = item.toString();
        if (value.trim().isNotEmpty) myReactions.add(value);
      }
    }

    final sender = row['sender'];
    final profile = sender is Map ? sender : const <String, dynamic>{};

    return EventMessage(
      id: row['id']?.toString() ?? '',
      eventId: row['event_id']?.toString() ?? '',
      senderId: row['sender_id']?.toString() ?? '',
      kind: row['kind']?.toString() ?? 'text',
      body: row['body']?.toString(),
      mediaUrl: row['media_url']?.toString(),
      stickerId: row['sticker_id']?.toString(),
      createdAt: _date(row['created_at']),
      senderDisplayName: profile['display_name']?.toString() ??
          row['sender_display_name']?.toString(),
      senderAvatarUrl: profile['avatar_url']?.toString() ??
          row['sender_avatar_url']?.toString(),
      reactionCounts: reactionCounts,
      myReactions: myReactions,
    );
  }

  EventMessage copyWith({
    String? id,
    String? eventId,
    String? senderId,
    String? kind,
    String? body,
    String? mediaUrl,
    String? stickerId,
    DateTime? createdAt,
    String? senderDisplayName,
    String? senderAvatarUrl,
    Map<String, int>? reactionCounts,
    List<String>? myReactions,
  }) =>
      EventMessage(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        senderId: senderId ?? this.senderId,
        kind: kind ?? this.kind,
        body: body ?? this.body,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        stickerId: stickerId ?? this.stickerId,
        createdAt: createdAt ?? this.createdAt,
        senderDisplayName: senderDisplayName ?? this.senderDisplayName,
        senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
        reactionCounts: reactionCounts ?? this.reactionCounts,
        myReactions: myReactions ?? this.myReactions,
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'event_id': eventId,
        'sender_id': senderId,
        'kind': kind,
        'body': body,
        'media_url': mediaUrl,
        'sticker_id': stickerId,
        'created_at': createdAt.toIso8601String(),
      };

  static DateTime _date(Object? value) {
    if (value == null) return DateTime.now();
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
