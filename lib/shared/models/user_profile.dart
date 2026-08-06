import 'enums.dart';

/// User profile — mirrors the `profiles` table in Supabase.
/// Source: types/database.ts → profiles.Row
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.avatarUrl,
    this.avatarColor = '#7B61FF',
    this.initials = 'FT',
    this.bio = '',
    this.role = UserRole.attendee,
    this.accountStatus = AccountStatus.active,
    this.loyaltyPoints = 0,
    this.isVip = false,
    this.totalSpent = 0.0,
    this.eventsAttended = 0,
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? avatarUrl;
  final String avatarColor;
  final String initials;
  final String bio;
  final UserRole role;
  final AccountStatus accountStatus;
  final int loyaltyPoints;
  final bool isVip;
  final double totalSpent;
  final int eventsAttended;
  final DateTime? createdAt;

  bool get isOrganizer => role.isOrganizer;
  bool get isAdmin => role.isAdmin;
  bool get isStaff => role.isStaff;
  bool get isActive => accountStatus == AccountStatus.active;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String? ?? '',
    displayName: json['display_name'] as String? ??
        (json['email'] as String? ?? '').split('@').first,
    phone: json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    avatarColor: json['avatar_color'] as String? ?? '#7B61FF',
    initials: json['initials'] as String? ?? 'FT',
    bio: json['bio'] as String? ?? '',
    role: UserRole.fromString(json['role'] as String?),
    accountStatus:
        AccountStatus.fromString(json['account_status'] as String?),
    loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
    isVip: json['is_vip'] as bool? ?? false,
    totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
    eventsAttended: (json['events_attended'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  UserProfile copyWith({
    String? displayName,
    String? phone,
    String? avatarUrl,
    String? bio,
    UserRole? role,
  }) => UserProfile(
    id: id,
    email: email,
    displayName: displayName ?? this.displayName,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    avatarColor: avatarColor,
    initials: initials,
    bio: bio ?? this.bio,
    role: role ?? this.role,
    accountStatus: accountStatus,
    loyaltyPoints: loyaltyPoints,
    isVip: isVip,
    totalSpent: totalSpent,
    eventsAttended: eventsAttended,
    createdAt: createdAt,
  );
}
