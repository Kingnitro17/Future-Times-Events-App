/// User roles matching the website's UserRole type.
/// Source: types/database.ts
enum UserRole {
  attendee,
  host,
  eventManager,  // 'event_manager' in DB
  admin,
  superAdmin;    // 'super_admin' in DB

  static UserRole fromString(String? value) {
    return switch (value) {
      'attendee'      => UserRole.attendee,
      'host'          => UserRole.host,
      'event_manager' => UserRole.eventManager,
      'organizer'     => UserRole.eventManager, // legacy alias
      'admin'         => UserRole.admin,
      'super_admin'   => UserRole.superAdmin,
      'user'          => UserRole.attendee,     // legacy alias
      _               => UserRole.attendee,
    };
  }

  String get value => switch (this) {
    UserRole.attendee     => 'attendee',
    UserRole.host         => 'host',
    UserRole.eventManager => 'event_manager',
    UserRole.admin        => 'admin',
    UserRole.superAdmin   => 'super_admin',
  };

  bool get isOrganizer =>
      this == UserRole.eventManager ||
      this == UserRole.admin ||
      this == UserRole.superAdmin;

  bool get isAdmin =>
      this == UserRole.admin || this == UserRole.superAdmin;

  bool get isStaff =>
      this == UserRole.host || isOrganizer;
}

/// Account status.
enum AccountStatus {
  active,
  suspended,
  deleted;

  static AccountStatus fromString(String? value) => switch (value) {
    'active'    => AccountStatus.active,
    'suspended' => AccountStatus.suspended,
    'deleted'   => AccountStatus.deleted,
    _           => AccountStatus.active,
  };
}

/// Event status matching EventStatus in database.ts
enum EventStatus {
  draft,
  scheduled,
  published,
  soldOut,
  completed,
  cancelled,
  postponed,
  archived;

  static EventStatus fromString(String? value) => switch (value) {
    'draft'     => EventStatus.draft,
    'scheduled' => EventStatus.scheduled,
    'published' => EventStatus.published,
    'sold_out'  => EventStatus.soldOut,
    'completed' => EventStatus.completed,
    'cancelled' => EventStatus.cancelled,
    'postponed' => EventStatus.postponed,
    'archived'  => EventStatus.archived,
    _           => EventStatus.draft,
  };

  bool get isPubliclyVisible =>
      this == EventStatus.published || this == EventStatus.soldOut;

  String get label => switch (this) {
    EventStatus.draft     => 'Draft',
    EventStatus.scheduled => 'Scheduled',
    EventStatus.published => 'Live',
    EventStatus.soldOut   => 'Sold Out',
    EventStatus.completed => 'Completed',
    EventStatus.cancelled => 'Cancelled',
    EventStatus.postponed => 'Postponed',
    EventStatus.archived  => 'Archived',
  };
}

/// Ticket status matching TicketStatus in database.ts
enum TicketStatus {
  issued,
  checkedIn,
  cancelled,
  revoked;

  static TicketStatus fromString(String? value) => switch (value) {
    'issued'     => TicketStatus.issued,
    'checked_in' => TicketStatus.checkedIn,
    'cancelled'  => TicketStatus.cancelled,
    'revoked'    => TicketStatus.revoked,
    _            => TicketStatus.issued,
  };

  bool get isValid => this == TicketStatus.issued;

  String get label => switch (this) {
    TicketStatus.issued    => 'Valid',
    TicketStatus.checkedIn => 'Used',
    TicketStatus.cancelled => 'Cancelled',
    TicketStatus.revoked   => 'Revoked',
  };
}

/// QR scan result — matches ScanResult in database.ts
enum ScanResult {
  validCheckedIn,
  alreadyCheckedIn,
  notFound,
  wrongEvent,
  cancelled,
  revoked,
  invalidStatus,
  invalidToken,
  eventNotOpen;

  static ScanResult fromString(String? value) => switch (value) {
    'valid_checked_in'  => ScanResult.validCheckedIn,
    'already_checked_in'=> ScanResult.alreadyCheckedIn,
    'not_found'         => ScanResult.notFound,
    'wrong_event'       => ScanResult.wrongEvent,
    'cancelled'         => ScanResult.cancelled,
    'revoked'           => ScanResult.revoked,
    'invalid_status'    => ScanResult.invalidStatus,
    'invalid_token'     => ScanResult.invalidToken,
    'event_not_open'    => ScanResult.eventNotOpen,
    _                   => ScanResult.invalidToken,
  };

  String get label => switch (this) {
    ScanResult.validCheckedIn   => 'Admitted',
    ScanResult.alreadyCheckedIn => 'Already scanned',
    ScanResult.notFound         => 'Ticket not found',
    ScanResult.wrongEvent       => 'Wrong event',
    ScanResult.cancelled        => 'Ticket cancelled',
    ScanResult.revoked          => 'Ticket revoked',
    ScanResult.invalidStatus    => 'Ticket is not valid',
    ScanResult.invalidToken     => 'Invalid QR code',
    ScanResult.eventNotOpen     => 'Check-in not open',
  };

  bool get isSuccess => this == ScanResult.validCheckedIn;
  bool get isWarning => this == ScanResult.alreadyCheckedIn;
}
