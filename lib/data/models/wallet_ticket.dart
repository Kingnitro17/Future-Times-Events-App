class WalletTicket {
  const WalletTicket(
      {required this.id,
      required this.ticketNumber,
      required this.eventId,
      required this.status,
      required this.issuedAt,
      required this.attendeeName,
      required this.attendeeEmail,
      required this.eventTitle,
      required this.eventStart,
      required this.venue,
      required this.imageUrl,
      required this.ticketType,
      this.qrPayload,
      this.checkedInAt,
      this.gate});

  final String id;
  final String ticketNumber;
  final String eventId;
  final String status;
  final DateTime issuedAt;
  final DateTime? checkedInAt;
  final String? gate;
  final String attendeeName;
  final String attendeeEmail;
  final String eventTitle;
  final DateTime? eventStart;
  final String venue;
  final String imageUrl;
  final String ticketType;
  final String? qrPayload;

  bool get isActive => status == 'issued';
  bool get isUsed => status == 'checked_in';
  bool get isViewable => isActive || isUsed;

  /// Returns the database QR code or a deterministic fallback for viewable tickets.
  String get effectiveQrPayload =>
      qrPayload ?? 'FTE:$eventId:$ticketNumber';

  factory WalletTicket.fromSupabase(Map<String, dynamic> row) {
    final eventRaw = row['events'];
    final Map<String, dynamic> event = eventRaw is Map<String, dynamic>
        ? eventRaw
        : (eventRaw is List &&
                eventRaw.isNotEmpty &&
                eventRaw.first is Map<String, dynamic>
            ? eventRaw.first as Map<String, dynamic>
            : const {});

    final typeRaw = row['ticket_type'] ?? row['ticket_types'];
    final Map<String, dynamic> type = typeRaw is Map<String, dynamic>
        ? typeRaw
        : (typeRaw is List &&
                typeRaw.isNotEmpty &&
                typeRaw.first is Map<String, dynamic>
            ? typeRaw.first as Map<String, dynamic>
            : const {});

    final date = event['date']?.toString();
    final time = event['time']?.toString();
    final startsAt = event['starts_at']?.toString() ??
        (date == null ? null : '${date}T${time ?? '00:00:00'}');
    return WalletTicket(
      id: row['id'].toString(),
      ticketNumber: row['ticket_number']?.toString() ??
          row['ticket_id']?.toString() ??
          row['id'].toString(),
      eventId: row['event_id'].toString(),
      status: row['status']?.toString() ?? 'issued',
      issuedAt: DateTime.tryParse(row['issued_at']?.toString() ?? '') ??
          DateTime.tryParse(row['purchased_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      checkedInAt: DateTime.tryParse(row['checked_in_at']?.toString() ?? ''),
      gate: _nonEmpty(row['gate']),
      attendeeName: row['attendee_name']?.toString() ??
          row['holder_name']?.toString() ??
          'Ticket holder',
      attendeeEmail: row['attendee_email']?.toString() ??
          row['holder_email']?.toString() ??
          '',
      eventTitle: event['title']?.toString() ?? 'Event',
      eventStart: DateTime.tryParse(startsAt ?? ''),
      venue: event['venue_name']?.toString() ??
          event['venue']?.toString() ??
          'Venue TBA',
      imageUrl: event['image_url']?.toString() ?? '',
      ticketType: type['name']?.toString() ?? 'General Admission',
      qrPayload: _nonEmpty(row['qr_code']),
    );
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
