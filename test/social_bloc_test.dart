import 'package:flutter_test/flutter_test.dart';
import 'package:future_times_events/data/models/attendee_model.dart';
import 'package:future_times_events/data/repositories/social_repository.dart';
import 'package:future_times_events/logic/blocs/social/social_bloc.dart';
import 'package:future_times_events/logic/blocs/social/social_event.dart';
import 'package:future_times_events/logic/blocs/social/social_state.dart';

void main() {
  test('uses authoritative count instead of capped preview length', () async {
    final repository = _FakeSocialRepository(
      attendees: const [
        AttendeeModel(
          userId: 'user-1',
          eventId: 'event-1',
          displayName: 'Tariro',
        ),
        AttendeeModel(
          userId: 'user-2',
          eventId: 'event-1',
          displayName: 'Simba',
        ),
      ],
      goingCount: 37,
    );
    final bloc = SocialBloc(socialRepository: repository);

    bloc.add(const WatchAttendees(eventId: 'event-1'));
    final loaded = await bloc.stream
        .firstWhere((state) => state is SocialLoaded) as SocialLoaded;

    expect(loaded.eventId, 'event-1');
    expect(loaded.attendees, hasLength(2));
    expect(loaded.attendeeCount, 37);
    await bloc.close();
  });
}

class _FakeSocialRepository implements SocialRepository {
  _FakeSocialRepository({required this.attendees, required this.goingCount});

  final List<AttendeeModel> attendees;
  final int goingCount;

  @override
  Future<List<AttendeeModel>> getAttendees(String eventId) async => attendees;

  @override
  Future<int> getAttendeeCount(String eventId) async => goingCount;

  @override
  Future<bool> hasCheckedIn(
          {required String eventId, required String userId}) async =>
      false;

  @override
  Future<void> checkIn({
    required String eventId,
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {}

  @override
  Future<void> checkOut(
      {required String eventId, required String userId}) async {}

  @override
  Stream<List<AttendeeModel>> watchAttendees(String eventId) =>
      Stream.value(attendees);

  @override
  Stream<int> watchAttendeeCount(String eventId) => Stream.value(goingCount);
}
