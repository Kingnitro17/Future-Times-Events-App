import '../../data/models/event_model.dart';

bool _isProductionEvent(EventModel event) {
  final status = event.status?.trim().toLowerCase();
  if (status == null || status.isEmpty) return true;
  return !{
    'archived',
    'cancelled',
    'completed',
    'draft',
    'sold_out',
    'postponed',
    'deleted',
  }.contains(status);
}

DateTime _eventStart(EventModel event) {
  final raw = event.start.local;
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return parsed;
  final alt = DateTime.tryParse(event.start.utc);
  return alt ?? DateTime.now();
}

List<EventModel> _futureDiscoverableEvents(List<EventModel> events) {
  final now = DateTime.now();
  return events
      .where((event) => _isProductionEvent(event))
      .where((event) => _eventStart(event).isAfter(now))
      .toList()
    ..sort((a, b) => _eventStart(a).compareTo(_eventStart(b)));
}

List<EventModel> rankHomeEvents(
  List<EventModel> events, {
  required String preferredCity,
  required Set<String> interests,
}) {
  final normalizedInterests = interests
      .map((item) => item.trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .toSet();
  final base = _futureDiscoverableEvents(events);
  if (base.isEmpty) return const [];

  final city = preferredCity.trim().toLowerCase();
  final ranked = [...base];
  ranked.sort((a, b) {
    int score(EventModel event) {
      var value = event.featured ? 1000 : 200;
      final eventCity = (event.venue?.address?.city ?? '').trim().toLowerCase();
      if (city.isNotEmpty && eventCity == city) value += 250;
      final category =
          (event.categoryLabel ?? event.categoryId ?? '').trim().toLowerCase();
      if (normalizedInterests.isNotEmpty &&
          normalizedInterests.any((interest) =>
              category.contains(interest) || interest.contains(category))) {
        value += 150;
      }

      final now = DateTime.now();
      final distanceMinutes =
          _eventStart(event).difference(now).inMinutes.abs();
      value += (5000 - distanceMinutes.clamp(0, 5000) ~/ 10).clamp(0, 5000);
      return value;
    }

    final scoreDelta = score(b).compareTo(score(a));
    if (scoreDelta != 0) return scoreDelta;
    return _eventStart(a).compareTo(_eventStart(b));
  });

  return ranked;
}

DateTime nextWeekendStartForHarare(DateTime anchor) {
  final harare = anchor.toUtc().add(const Duration(hours: 2));
  final today = DateTime(harare.year, harare.month, harare.day);
  final daysUntilSaturday = (DateTime.saturday - today.weekday) % 7;
  final weekendStart =
      today.add(Duration(days: daysUntilSaturday == 0 ? 0 : daysUntilSaturday));
  return weekendStart;
}

List<EventModel> filterExploreEvents(
  List<EventModel> events, {
  String query = '',
  String? category,
  String? city,
  DateTime? startDate,
  DateTime? endDate,
  bool? isFree,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final items = events.where(_isProductionEvent).where((event) {
    if (startDate != null) {
      final eventDate = _eventStart(event);
      if (eventDate.isBefore(startDate)) return false;
    }
    if (endDate != null) {
      final eventDate = _eventStart(event);
      final endBoundary =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      if (eventDate.isAfter(endBoundary)) return false;
    }
    if (category != null && category.trim().isNotEmpty) {
      final categoryMatch = (event.categoryId ?? '').toLowerCase() ==
              category.toLowerCase() ||
          (event.categoryLabel ?? '').toLowerCase() == category.toLowerCase();
      if (!categoryMatch) return false;
    }
    if (city != null && city.trim().isNotEmpty) {
      final eventCity = (event.venue?.address?.city ?? '').trim().toLowerCase();
      if (eventCity != city.trim().toLowerCase()) return false;
    }
    if (isFree != null && event.isFree != isFree) return false;
    if (normalizedQuery.isEmpty) return true;

    final haystack = [
      event.name.text,
      event.categoryLabel ?? '',
      event.categoryId ?? '',
      event.venue?.name ?? '',
      event.venue?.address?.city ?? '',
      event.venue?.address?.localizedDisplay ?? '',
      event.organizerName ?? '',
      event.tags.join(' '),
      event.lineup.join(' '),
    ].join(' ').toLowerCase();
    return haystack.contains(normalizedQuery);
  }).toList();

  items.sort((a, b) => _eventStart(a).compareTo(_eventStart(b)));
  return items;
}
