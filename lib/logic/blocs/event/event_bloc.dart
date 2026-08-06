import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/event_repository.dart';
import 'event_event.dart';
import 'event_state.dart';

class EventBloc extends Bloc<EventEvent, EventState> {
  EventBloc({required EventRepository repository})
      : _repository = repository,
        super(const EventInitial()) {
    on<FetchEvents>(_onFetchEvents);
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchEvents>(_onSearchEvents);
    on<ApplyFilters>(_onApplyFilters);
    on<LoadMoreEvents>(_onLoadMore);
    on<ClearFilters>(_onClearFilters);
  }

  final EventRepository _repository;

  // ─── FetchEvents ───────────────────────────────────────────────────────────

  Future<void> _onFetchEvents(
    FetchEvents event,
    Emitter<EventState> emit,
  ) async {
    emit(const EventLoading());
    try {
      final response = await _repository.getEvents(
        locationAddress: event.locationAddress,
        locationLatitude: event.locationLatitude,
        locationLongitude: event.locationLongitude,
        forceRefresh: event.forceRefresh,
        page: 1,
      );
      emit(EventLoaded(
        events: response.events,
        currentPage: 1,
        hasMore: response.pagination.hasMoreItems,
      ));
    } catch (e) {
      emit(EventError(message: _friendlyError(e)));
    }
  }

  // ─── FilterByCategory ──────────────────────────────────────────────────────

  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<EventState> emit,
  ) async {
    final current = state;
    final baseState = current is EventLoaded ? current : null;

    emit(const EventLoading());
    try {
      final response = await _repository.getEvents(
        categoryId: event.categoryId.isEmpty ? null : event.categoryId,
        page: 1,
        forceRefresh: true,
      );
      emit(EventLoaded(
        events: response.events,
        currentPage: 1,
        hasMore: response.pagination.hasMoreItems,
        activeCategoryId: event.categoryId.isEmpty ? null : event.categoryId,
        activeCategoryName:
            event.categoryId.isEmpty ? null : event.categoryName,
        activeQuery: baseState?.activeQuery,
        activeStartDate: baseState?.activeStartDate,
        activeEndDate: baseState?.activeEndDate,
        activeIsFree: baseState?.activeIsFree,
      ));
    } catch (e) {
      emit(EventError(message: _friendlyError(e)));
    }
  }

  // ─── SearchEvents ──────────────────────────────────────────────────────────

  Future<void> _onSearchEvents(
    SearchEvents event,
    Emitter<EventState> emit,
  ) async {
    final current = state;
    final baseState = current is EventLoaded ? current : null;

    if (event.query.isEmpty) {
      add(const FetchEvents(forceRefresh: true));
      return;
    }

    emit(const EventLoading());
    try {
      final response = await _repository.getEvents(
        query: event.query,
        categoryId: baseState?.activeCategoryId,
        isFree: baseState?.activeIsFree,
        page: 1,
        forceRefresh: true,
      );
      emit(EventLoaded(
        events: response.events,
        currentPage: 1,
        hasMore: response.pagination.hasMoreItems,
        activeCategoryId: baseState?.activeCategoryId,
        activeCategoryName: baseState?.activeCategoryName,
        activeQuery: event.query,
        activeStartDate: baseState?.activeStartDate,
        activeEndDate: baseState?.activeEndDate,
        activeIsFree: baseState?.activeIsFree,
      ));
    } catch (e) {
      emit(EventError(message: _friendlyError(e)));
    }
  }

  // ─── ApplyFilters ──────────────────────────────────────────────────────────

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<EventState> emit,
  ) async {
    final current = state;
    final baseState = current is EventLoaded ? current : null;

    emit(const EventLoading());
    try {
      final response = await _repository.getEvents(
        categoryId: baseState?.activeCategoryId,
        query: baseState?.activeQuery,
        isFree: event.isFree,
        startDateRangeStart: event.startDate?.toIso8601String(),
        startDateRangeEnd: event.endDate?.toIso8601String(),
        page: 1,
        forceRefresh: true,
      );
      emit(EventLoaded(
        events: response.events,
        currentPage: 1,
        hasMore: response.pagination.hasMoreItems,
        activeCategoryId: baseState?.activeCategoryId,
        activeCategoryName: baseState?.activeCategoryName,
        activeQuery: baseState?.activeQuery,
        activeStartDate: event.startDate,
        activeEndDate: event.endDate,
        activeIsFree: event.isFree,
      ));
    } catch (e) {
      emit(EventError(message: _friendlyError(e)));
    }
  }

  // ─── LoadMore ──────────────────────────────────────────────────────────────

  Future<void> _onLoadMore(
    LoadMoreEvents event,
    Emitter<EventState> emit,
  ) async {
    final current = state;
    if (current is! EventLoaded || !current.hasMore || current.isPaginating) {
      return;
    }

    final nextPage = current.currentPage + 1;
    emit(current.copyWith(isPaginating: true));

    try {
      final response = await _repository.getEvents(
        categoryId: current.activeCategoryId,
        query: current.activeQuery,
        isFree: current.activeIsFree,
        startDateRangeStart: current.activeStartDate?.toIso8601String(),
        startDateRangeEnd: current.activeEndDate?.toIso8601String(),
        page: nextPage,
        forceRefresh: true,
      );

      emit(current.copyWith(
        events: [...current.events, ...response.events],
        currentPage: nextPage,
        hasMore: response.pagination.hasMoreItems,
        isPaginating: false,
      ));
    } catch (e) {
      // Pagination errors are non-fatal; revert isPaginating
      emit(current.copyWith(isPaginating: false));
    }
  }

  // ─── ClearFilters ──────────────────────────────────────────────────────────

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<EventState> emit,
  ) async {
    _repository.clearCache();
    add(const FetchEvents(forceRefresh: true));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('token') || msg.contains('401')) {
      return 'API authentication failed. Check your Eventbrite token.';
    }
    if (msg.contains('SocketException') || msg.contains('network')) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
