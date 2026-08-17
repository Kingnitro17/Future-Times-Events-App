import 'event_model.dart';

class EventListResponse {
  const EventListResponse({required this.events, required this.pagination});
  final List<EventModel> events;
  final PaginationMeta pagination;
}

class PaginationMeta {
  const PaginationMeta({
    required this.objectCount,
    required this.pageNumber,
    required this.pageSize,
    required this.pageCount,
    required this.hasMoreItems,
  });
  final int objectCount;
  final int pageNumber;
  final int pageSize;
  final int pageCount;
  final bool hasMoreItems;
}
