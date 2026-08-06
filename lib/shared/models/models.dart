import 'enums.dart';

/// Event model — mirrors the `events` table in Supabase.
/// Source: types/database.ts → events.Row
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.categoryLabel,
    required this.description,
    required this.longDescription,
    required this.status,
    required this.startsAt,
    required this.venueName,
    required this.city,
    this.subtitle,
    this.endsAt,
    this.doorsOpenAt,
    this.coverImageUrl,
    this.imageUrl,
    this.timezone = 'Africa/Harare',
    this.venueId,
    this.venue = '',
    this.address = '',
    this.lat,
    this.lng,
    this.capacity = 0,
    this.attendees = 0,
    this.dressCode,
    this.ageGuidance,
    this.eventRules,
    this.contactEmail,
    this.organizerId,
    this.organizerName = '',
    this.tags = const [],
    this.featured = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String slug;
  final String? subtitle;
  final String category;
  final String categoryLabel;
  final String description;
  final String longDescription;
  final EventStatus status;
  final bool featured;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime? doorsOpenAt;
  final String? coverImageUrl;
  final String? imageUrl;
  final String timezone;
  final String? venueId;
  final String venue;
  final String venueName;
  final String address;
  final String city;
  final double? lat;
  final double? lng;
  final int capacity;
  final int attendees;
  final String? dressCode;
  final String? ageGuidance;
  final String? eventRules;
  final String? contactEmail;
  final String? organizerId;
  final String organizerName;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Best available image URL — cover first, then image.
  String? get bestImageUrl => coverImageUrl ?? imageUrl;

  /// Whether tickets can currently be sold/claimed.
  bool get isSalesOpen =>
      status == EventStatus.published &&
      startsAt.isAfter(DateTime.now());

  /// Whether the event is sold out.
  bool get isSoldOut => status == EventStatus.soldOut;

  /// Whether the event has already happened.
  bool get isPast =>
      status == EventStatus.completed ||
      (endsAt != null && endsAt!.isBefore(DateTime.now())) ||
      (endsAt == null && startsAt.isBefore(
          DateTime.now().subtract(const Duration(hours: 4))));

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] as String,
    title: json['title'] as String,
    slug: json['slug'] as String,
    subtitle: json['subtitle'] as String?,
    category: json['category'] as String? ?? '',
    categoryLabel: json['category_label'] as String? ?? '',
    description: json['description'] as String? ?? '',
    longDescription: json['long_description'] as String? ?? '',
    status: EventStatus.fromString(json['status'] as String?),
    featured: json['featured'] as bool? ?? false,
    startsAt: DateTime.parse(
        (json['starts_at'] as String?) ?? DateTime.now().toIso8601String()),
    endsAt: json['ends_at'] != null
        ? DateTime.tryParse(json['ends_at'] as String)
        : null,
    doorsOpenAt: json['doors_open_at'] != null
        ? DateTime.tryParse(json['doors_open_at'] as String)
        : null,
    coverImageUrl: json['cover_image_url'] as String?,
    imageUrl: json['image_url'] as String?,
    timezone: json['timezone'] as String? ?? 'Africa/Harare',
    venueId: json['venue_id'] as String?,
    venue: json['venue'] as String? ?? '',
    venueName: json['venue_name'] as String? ?? '',
    address: json['address'] as String? ?? '',
    city: json['city'] as String? ?? '',
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    attendees: (json['attendees'] as num?)?.toInt() ?? 0,
    dressCode: json['dress_code'] as String?,
    ageGuidance: json['age_guidance'] as String?,
    eventRules: json['event_rules'] as String?,
    contactEmail: json['contact_email'] as String?,
    organizerId: json['organizer_id'] as String?,
    organizerName: json['organizer_name'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
  );
}

/// Ticket type — mirrors the `ticket_types` table.
class TicketType {
  const TicketType({
    required this.id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.quantityTotal,
    required this.quantityAvailable,
    this.description = '',
    this.claimLimitPerContact = 1,
    this.claimOpensAt,
    this.claimClosesAt,
    this.isActive = true,
    this.isVisible = true,
    this.sortOrder = 0,
  });

  final String id;
  final String eventId;
  final String name;
  final String description;
  final double price;
  final int quantityTotal;
  final int quantityAvailable;
  final int claimLimitPerContact;
  final DateTime? claimOpensAt;
  final DateTime? claimClosesAt;
  final bool isActive;
  final bool isVisible;
  final int sortOrder;

  bool get isFree => price == 0.0;
  bool get isAvailable => isActive && isVisible && quantityAvailable > 0;

  bool get isSalesOpen {
    final now = DateTime.now();
    if (claimOpensAt != null && now.isBefore(claimOpensAt!)) return false;
    if (claimClosesAt != null && now.isAfter(claimClosesAt!)) return false;
    return isActive;
  }

  factory TicketType.fromJson(Map<String, dynamic> json) => TicketType(
    id: json['id'] as String,
    eventId: json['event_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    quantityTotal: (json['quantity_total'] as num?)?.toInt() ?? 0,
    quantityAvailable:
        (json['quantity_available'] as num?)?.toInt() ?? 0,
    claimLimitPerContact:
        (json['claim_limit_per_contact'] as num?)?.toInt() ?? 1,
    claimOpensAt: json['claim_opens_at'] != null
        ? DateTime.tryParse(json['claim_opens_at'] as String)
        : null,
    claimClosesAt: json['claim_closes_at'] != null
        ? DateTime.tryParse(json['claim_closes_at'] as String)
        : null,
    isActive: json['is_active'] as bool? ?? true,
    isVisible: json['is_visible'] as bool? ?? true,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );
}

/// Issued ticket — mirrors the `tickets` table.
/// NOTE: qrRawToken is NOT stored in the database (only qr_token_hash is).
/// The raw token is returned once by the claim RPC and stored in secure storage.
class Ticket {
  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.eventId,
    required this.ticketTypeId,
    required this.attendeeName,
    required this.attendeeEmail,
    required this.status,
    required this.issuedAt,
    this.ticketSequence = 0,
    this.claimId,
    this.userId,
    this.attendeePhone,
    this.checkedInAt,
    this.gate,
    this.cancellationReason,
    this.quantity = 1,
    // Joined fields from related tables:
    this.eventTitle,
    this.eventStartsAt,
    this.eventVenueName,
    this.eventCity,
    this.eventCoverImageUrl,
    this.ticketTypeName,
    this.ticketTypePrice,
  });

  final String id;
  final String ticketNumber;
  final int ticketSequence;
  final String eventId;
  final String ticketTypeId;
  final String? claimId;
  final String? userId;
  final String attendeeName;
  final String attendeeEmail;
  final String? attendeePhone;
  final TicketStatus status;
  final int quantity;
  final DateTime issuedAt;
  final DateTime? checkedInAt;
  final String? gate;
  final String? cancellationReason;

  // Joined from events / ticket_types
  final String? eventTitle;
  final DateTime? eventStartsAt;
  final String? eventVenueName;
  final String? eventCity;
  final String? eventCoverImageUrl;
  final String? ticketTypeName;
  final double? ticketTypePrice;

  bool get isValid => status == TicketStatus.issued;
  bool get isUsed => status == TicketStatus.checkedIn;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Support both flat and joined responses
    final eventJson =
        json['events'] as Map<String, dynamic>?;
    final ticketTypeJson =
        json['ticket_types'] as Map<String, dynamic>?;

    return Ticket(
      id: json['id'] as String,
      ticketNumber: json['ticket_number'] as String,
      ticketSequence: (json['ticket_sequence'] as num?)?.toInt() ?? 0,
      eventId: json['event_id'] as String,
      ticketTypeId: json['ticket_type_id'] as String,
      claimId: json['claim_id'] as String?,
      userId: json['user_id'] as String?,
      attendeeName: json['attendee_name'] as String,
      attendeeEmail: json['attendee_email'] as String,
      attendeePhone: json['attendee_phone'] as String?,
      status: TicketStatus.fromString(json['status'] as String?),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      issuedAt: DateTime.parse(
          (json['issued_at'] as String?) ?? DateTime.now().toIso8601String()),
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'] as String)
          : null,
      gate: json['gate'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      // Joined event fields
      eventTitle: eventJson?['title'] as String? ?? json['event_title'] as String?,
      eventStartsAt: eventJson?['starts_at'] != null
          ? DateTime.tryParse(eventJson!['starts_at'] as String)
          : json['event_starts_at'] != null
              ? DateTime.tryParse(json['event_starts_at'] as String)
              : null,
      eventVenueName: eventJson?['venue_name'] as String? ??
          json['event_venue_name'] as String?,
      eventCity: eventJson?['city'] as String? ?? json['event_city'] as String?,
      eventCoverImageUrl: eventJson?['cover_image_url'] as String? ??
          json['event_cover_image_url'] as String?,
      ticketTypeName: ticketTypeJson?['name'] as String? ??
          json['ticket_type_name'] as String?,
      ticketTypePrice:
          (ticketTypeJson?['price'] as num?)?.toDouble() ??
          (json['ticket_type_price'] as num?)?.toDouble(),
    );
  }
}
