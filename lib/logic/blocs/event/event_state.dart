import 'package:equatable/equatable.dart';
import '../../../data/models/event_model.dart';

abstract class EventState extends Equatable {
  const EventState();

  @override
  List<Object?> get props => [];
}

/// Before any fetch has been triggered.
class EventInitial extends EventState {
  const EventInitial();
}

/// First-page load in progress (shows skeleton UI).
class EventLoading extends EventState {
  const EventLoading();
}

/// Successfully loaded events.
class EventLoaded extends EventState {
  const EventLoaded({
    required this.events,
    required this.currentPage,
    required this.hasMore,
    this.activeCategoryId,
    this.activeCategoryName,
    this.activeQuery,
    this.activeStartDate,
    this.activeEndDate,
    this.activeIsFree,
    this.activeCity,
    this.isPaginating = false,
  });

  final List<EventModel> events;
  final int currentPage;
  final bool hasMore;

  // Active filter state (preserved across pages)
  final String? activeCategoryId;
  final String? activeCategoryName;
  final String? activeQuery;
  final DateTime? activeStartDate;
  final DateTime? activeEndDate;
  final bool? activeIsFree;
  final String? activeCity;

  /// True when loading additional pages (bottom-of-list spinner).
  final bool isPaginating;

  EventLoaded copyWith({
    List<EventModel>? events,
    int? currentPage,
    bool? hasMore,
    String? activeCategoryId,
    String? activeCategoryName,
    String? activeQuery,
    DateTime? activeStartDate,
    DateTime? activeEndDate,
    bool? activeIsFree,
    String? activeCity,
    bool? isPaginating,
  }) {
    return EventLoaded(
      events: events ?? this.events,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      activeCategoryId: activeCategoryId ?? this.activeCategoryId,
      activeCategoryName: activeCategoryName ?? this.activeCategoryName,
      activeQuery: activeQuery ?? this.activeQuery,
      activeStartDate: activeStartDate ?? this.activeStartDate,
      activeEndDate: activeEndDate ?? this.activeEndDate,
      activeIsFree: activeIsFree ?? this.activeIsFree,
      activeCity: activeCity ?? this.activeCity,
      isPaginating: isPaginating ?? this.isPaginating,
    );
  }

  bool get hasActiveFilters =>
      activeCategoryId != null ||
      activeQuery != null ||
      activeStartDate != null ||
      activeEndDate != null ||
      activeIsFree != null ||
      activeCity != null;

  @override
  List<Object?> get props => [
        events,
        currentPage,
        hasMore,
        activeCategoryId,
        activeCategoryName,
        activeQuery,
        activeStartDate,
        activeEndDate,
        activeIsFree,
        activeCity,
        isPaginating,
      ];
}

/// An error occurred fetching events.
class EventError extends EventState {
  const EventError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
