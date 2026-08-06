import 'package:equatable/equatable.dart';

abstract class EventEvent extends Equatable {
  const EventEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load or refresh — fetches first page with no filters.
class FetchEvents extends EventEvent {
  const FetchEvents({
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
    this.forceRefresh = false,
  });

  final String? locationAddress;
  final double? locationLatitude;
  final double? locationLongitude;
  final bool forceRefresh;

  @override
  List<Object?> get props => [
        locationAddress,
        locationLatitude,
        locationLongitude,
        forceRefresh,
      ];
}

/// Filter events by a specific category ID.
class FilterByCategory extends EventEvent {
  const FilterByCategory({required this.categoryId, this.categoryName = ''});

  final String categoryId;
  final String categoryName;

  @override
  List<Object?> get props => [categoryId, categoryName];
}

/// Full-text search across event names / descriptions.
class SearchEvents extends EventEvent {
  const SearchEvents({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Apply date and/or price filters from the filter bottom sheet.
class ApplyFilters extends EventEvent {
  const ApplyFilters({
    this.startDate,
    this.endDate,
    this.isFree,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isFree;

  @override
  List<Object?> get props => [startDate, endDate, isFree];
}

/// Paginate — load the next page of results.
class LoadMoreEvents extends EventEvent {
  const LoadMoreEvents();
}

/// Clear all active filters and search query.
class ClearFilters extends EventEvent {
  const ClearFilters();
}
