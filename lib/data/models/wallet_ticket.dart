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

  bool get isActive => status == 'issued';
  bool get isUsed => status == 'checked_in';
}
