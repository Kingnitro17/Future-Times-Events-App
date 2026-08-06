import 'dart:async';
import '../models/attendee_model.dart';

/// Manages the social "Who's Going" layer via Firebase Firestore.
/// Collection path: attendees/{eventId}/checkins/{userId}
class SocialRepository {
  SocialRepository(); // Removed Firebase dependency for UI-only mode

  // ─── Check In ─────────────────────────────────────────────────────────────

  Future<void> checkIn({
    required String eventId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    // TEMPORARILY MOCKED FOR UI ONLY
  }

  // ─── Check Out ────────────────────────────────────────────────────────────

  Future<void> checkOut({
    required String eventId,
    required String userId,
  }) async {
    // TEMPORARILY MOCKED FOR UI ONLY
  }

  // ─── Get Attendees (stream) ────────────────────────────────────────────────

  Stream<List<AttendeeModel>> watchAttendees(String eventId) {
    // TEMPORARILY MOCKED: Return fake attendees for UI testing
    return Stream.value([
      AttendeeModel(userId: '1', eventId: eventId, displayName: 'John Doe', avatarUrl: 'https://i.pravatar.cc/150?u=1'),
      AttendeeModel(userId: '2', eventId: eventId, displayName: 'Jane Smith', avatarUrl: 'https://i.pravatar.cc/150?u=2'),
      AttendeeModel(userId: '3', eventId: eventId, displayName: 'Alice J.', avatarUrl: 'https://i.pravatar.cc/150?u=3'),
      AttendeeModel(userId: '4', eventId: eventId, displayName: 'Bob Ross', avatarUrl: 'https://i.pravatar.cc/150?u=4'),
      AttendeeModel(userId: '5', eventId: eventId, displayName: 'Elon M.', avatarUrl: 'https://i.pravatar.cc/150?u=5'),
    ]);
  }

  // ─── Get Attendees (one-shot) ──────────────────────────────────────────────

  Future<List<AttendeeModel>> getAttendees(String eventId) async {
    return [
      AttendeeModel(userId: '1', eventId: eventId, displayName: 'John Doe', avatarUrl: 'https://i.pravatar.cc/150?u=1'),
      AttendeeModel(userId: '2', eventId: eventId, displayName: 'Jane Smith', avatarUrl: 'https://i.pravatar.cc/150?u=2'),
    ];
  }

  // ─── Has Checked In ────────────────────────────────────────────────────────

  Future<bool> hasCheckedIn({
    required String eventId,
    required String userId,
  }) async {
    return false;
  }

  // ─── Get Count ────────────────────────────────────────────────────────────

  Stream<int> watchAttendeeCount(String eventId) {
    return Stream.value(5);
  }
}
