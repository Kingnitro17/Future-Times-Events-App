class OrganizerApplication {
  const OrganizerApplication({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessRegistration,
    required this.contactPhone,
    required this.contactEmail,
    required this.description,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String userId;
  final String businessName;
  final String? businessRegistration;
  final String contactPhone;
  final String contactEmail;
  final String description;
  final String status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  factory OrganizerApplication.fromSupabase(Map<String, dynamic> row) {
    return OrganizerApplication(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      businessName: row['business_name']?.toString() ?? '',
      businessRegistration: row['business_registration']?.toString(),
      contactPhone: row['contact_phone']?.toString() ?? '',
      contactEmail: row['contact_email']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      status: row['status']?.toString() ?? 'pending',
      rejectionReason: row['rejection_reason']?.toString(),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      reviewedAt: DateTime.tryParse(row['reviewed_at']?.toString() ?? ''),
    );
  }

  bool get isPending => status == 'pending' || status == 'pending_review';
  bool get isRejected => status == 'rejected';
}
