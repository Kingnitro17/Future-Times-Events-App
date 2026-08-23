class AttendeeModel {
  const AttendeeModel({
    required this.userId,
    required this.eventId,
    required this.displayName,
    this.avatarUrl,
    this.checkedInAt,
    this.isFriend = false,
  });

  final String userId;
  final String eventId;
  final String displayName;
  final String? avatarUrl;
  final DateTime? checkedInAt;
  final bool isFriend;

  factory AttendeeModel.fromJson(Map<String, dynamic> json) {
    return AttendeeModel(
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      eventId:
          json['event_id']?.toString() ?? json['eventId']?.toString() ?? '',
      displayName: json['display_name']?.toString() ??
          json['displayName']?.toString() ??
          'Attendee',
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      checkedInAt: DateTime.tryParse(
          json['checkedInAt']?.toString() ?? json['rsvp_at']?.toString() ?? ''),
      isFriend: json['is_friend'] == true || json['is_following'] == true,
    );
  }
}
