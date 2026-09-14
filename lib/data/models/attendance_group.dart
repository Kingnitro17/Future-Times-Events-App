class AttendanceGroup {
  const AttendanceGroup({
    required this.id,
    required this.eventId,
    required this.name,
    this.meetingPoint,
    this.meetingLat,
    this.meetingLng,
    this.meetingTime,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String name;
  final String? meetingPoint;
  final double? meetingLat;
  final double? meetingLng;
  final DateTime? meetingTime;
  final String createdBy;
  final DateTime createdAt;

  factory AttendanceGroup.fromSupabase(Map<String, dynamic> row) =>
      AttendanceGroup(
        id: _string(row['id']),
        eventId: _string(row['event_id']),
        name: _string(row['name']),
        meetingPoint: _nullable(row['meeting_point']),
        meetingLat: _optionalDouble(row['meeting_lat']),
        meetingLng: _optionalDouble(row['meeting_lng']),
        meetingTime: _optionalDate(row['meeting_time']),
        createdBy: _string(row['created_by']),
        createdAt: _date(row['created_at']),
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'event_id': eventId,
        'name': name,
        'meeting_point': meetingPoint,
        'meeting_lat': meetingLat,
        'meeting_lng': meetingLng,
        'meeting_time': meetingTime?.toIso8601String(),
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  AttendanceGroup copyWith({
    String? id,
    String? eventId,
    String? name,
    String? meetingPoint,
    double? meetingLat,
    double? meetingLng,
    DateTime? meetingTime,
    String? createdBy,
    DateTime? createdAt,
  }) =>
      AttendanceGroup(
        id: id ?? this.id,
        eventId: eventId ?? this.eventId,
        name: name ?? this.name,
        meetingPoint: meetingPoint ?? this.meetingPoint,
        meetingLat: meetingLat ?? this.meetingLat,
        meetingLng: meetingLng ?? this.meetingLng,
        meetingTime: meetingTime ?? this.meetingTime,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );
}

class AttendanceGroupMember {
  const AttendanceGroupMember({
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  final String groupId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final String? displayName;
  final String? avatarUrl;

  factory AttendanceGroupMember.fromSupabase(Map<String, dynamic> row) {
    final profile = _nestedMap(row['profiles'] ?? row['profile']);
    return AttendanceGroupMember(
      groupId: _string(row['group_id']),
      userId: _string(row['user_id']),
      role: _string(row['role']),
      joinedAt: _date(row['joined_at']),
      displayName: _nullable(row['display_name'] ?? profile['display_name']),
      avatarUrl: _nullable(row['avatar_url'] ?? profile['avatar_url']),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'group_id': groupId,
        'user_id': userId,
        'role': role,
        'joined_at': joinedAt.toIso8601String(),
        'display_name': displayName,
        'avatar_url': avatarUrl,
      };

  AttendanceGroupMember copyWith({
    String? groupId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    String? displayName,
    String? avatarUrl,
  }) =>
      AttendanceGroupMember(
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        joinedAt: joinedAt ?? this.joinedAt,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

class GroupInvite {
  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.invitedBy,
    required this.invitedUser,
    required this.status,
    required this.createdAt,
    this.invitedByName,
    this.invitedUserName,
    this.groupName,
    this.eventTitle,
  });

  final String id;
  final String groupId;
  final String invitedBy;
  final String invitedUser;
  final String status;
  final DateTime createdAt;
  final String? invitedByName;
  final String? invitedUserName;
  final String? groupName;
  final String? eventTitle;

  factory GroupInvite.fromSupabase(Map<String, dynamic> row) {
    final inviter = _nestedMap(row['inviter'] ?? row['invited_by_profile']);
    final invitee = _nestedMap(row['invitee'] ?? row['invited_user_profile']);
    return GroupInvite(
      id: _string(row['id']),
      groupId: _string(row['group_id']),
      invitedBy: _string(row['invited_by']),
      invitedUser: _string(row['invited_user']),
      status: _string(row['status']),
      createdAt: _date(row['created_at']),
      invitedByName:
          _nullable(row['invited_by_name'] ?? inviter['display_name']),
      invitedUserName:
          _nullable(row['invited_user_name'] ?? invitee['display_name']),
      groupName:
          _nullable(row['group_name'] ?? _nestedMap(row['groups'])['name']),
      eventTitle: _nullable(row['event_title'] ??
          _nestedMap(_nestedMap(row['groups'])['events'])['title']),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'group_id': groupId,
        'invited_by': invitedBy,
        'invited_user': invitedUser,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  GroupInvite copyWith({
    String? id,
    String? groupId,
    String? invitedBy,
    String? invitedUser,
    String? status,
    DateTime? createdAt,
    String? invitedByName,
    String? invitedUserName,
    String? groupName,
    String? eventTitle,
  }) =>
      GroupInvite(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        invitedBy: invitedBy ?? this.invitedBy,
        invitedUser: invitedUser ?? this.invitedUser,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        invitedByName: invitedByName ?? this.invitedByName,
        invitedUserName: invitedUserName ?? this.invitedUserName,
        groupName: groupName ?? this.groupName,
        eventTitle: eventTitle ?? this.eventTitle,
      );
}

class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderDisplayName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String senderDisplayName;
  final String body;
  final DateTime createdAt;

  factory GroupMessage.fromSupabase(Map<String, dynamic> row) {
    final profile = _nestedMap(row['profiles'] ?? row['sender_profile']);
    return GroupMessage(
      id: _string(row['id']),
      groupId: _string(row['group_id']),
      senderId: _string(row['sender_id']),
      senderDisplayName: _string(
          row['sender_display_name'] ?? profile['display_name'] ?? 'Member'),
      body: _string(row['body']),
      createdAt: _date(row['created_at']),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'group_id': groupId,
        'sender_id': senderId,
        'sender_display_name': senderDisplayName,
        'body': body,
        'created_at': createdAt.toIso8601String(),
      };

  GroupMessage copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderDisplayName,
    String? body,
    DateTime? createdAt,
  }) =>
      GroupMessage(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        senderId: senderId ?? this.senderId,
        senderDisplayName: senderDisplayName ?? this.senderDisplayName,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
      );
}

class GroupExpense {
  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.paidByName,
    required this.description,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String paidBy;
  final String paidByName;
  final String description;
  final double amount;
  final String currency;
  final DateTime createdAt;

  factory GroupExpense.fromSupabase(Map<String, dynamic> row) {
    final profile = _nestedMap(row['profiles'] ?? row['payer_profile']);
    return GroupExpense(
      id: _string(row['id']),
      groupId: _string(row['group_id']),
      paidBy: _string(row['paid_by']),
      paidByName:
          _string(row['paid_by_name'] ?? profile['display_name'] ?? 'Member'),
      description: _string(row['description']),
      amount: _double(row['amount']),
      currency: _string(row['currency']),
      createdAt: _date(row['created_at']),
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'group_id': groupId,
        'paid_by': paidBy,
        'paid_by_name': paidByName,
        'description': description,
        'amount': amount,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
      };

  GroupExpense copyWith({
    String? id,
    String? groupId,
    String? paidBy,
    String? paidByName,
    String? description,
    double? amount,
    String? currency,
    DateTime? createdAt,
  }) =>
      GroupExpense(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        paidBy: paidBy ?? this.paidBy,
        paidByName: paidByName ?? this.paidByName,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        createdAt: createdAt ?? this.createdAt,
      );
}

String _string(Object? value) => value?.toString() ?? '';

String? _nullable(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

double? _optionalDouble(Object? value) => value == null
    ? null
    : value is num
        ? value.toDouble()
        : double.tryParse('$value');

double _double(Object? value) => _optionalDouble(value) ?? 0;

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

Map<String, dynamic> _nestedMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
