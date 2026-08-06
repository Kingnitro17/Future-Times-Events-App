import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/app_config.dart';
import '../data/event_repository.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/ft_widgets.dart';
import '../../../shared/widgets/event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _repo = EventRepository();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Event> _events = [];
  List<Event> _searchResults = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;

  String? _selectedCategory;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadEvents(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore &&
        !_isSearching) {
      _loadMore();
    }
  }

  Future<void> _loadEvents({bool reset = false}) async {
    if (reset) {
      setState(() { _page = 0; _events = []; _loading = true; _error = null; _hasMore = true; });
    }
    try {
      final results = await _repo.getEvents(
        category: _selectedCategory,
        page: reset ? 0 : _page,
      );
      if (mounted) {
        setState(() {
          _events = reset ? results : [..._events, ...results];
          _hasMore = results.length == AppConfig.eventPageSize;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    setState(() { _loadingMore = true; _page++; });
    try {
      final results = await _repo.getEvents(
        category: _selectedCategory,
        page: _page,
      );
      if (mounted) {
        setState(() {
          _events = [..._events, ...results];
          _hasMore = results.length == AppConfig.eventPageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingMore = false; _page--; });
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _isSearching = false; _searchResults = []; });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: AppConfig.searchDebounceMs),
      () => _runSearch(q),
    );
  }

  Future<void> _runSearch(String q) async {
    setState(() => _isSearching = true);
    try {
      final results = await _repo.searchEvents(q);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    }
  }

  void _selectCategory(String? cat) {
    setState(() => _selectedCategory = cat == _selectedCategory ? null : cat);
    _loadEvents(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text('Events', style: AppTypography.h3.copyWith(color: AppColors.text)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: _SearchAndFilter(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            selectedCategory: _selectedCategory,
            onCategorySelected: _selectCategory,
          ),
        ),
      ),
      body: _loading
          ? const _EventsListSkeleton()
          : _error != null
              ? FtErrorState(
                  message: 'Could not load events.',
                  onRetry: () => _loadEvents(reset: true),
                )
              : RefreshIndicator(
                  color: AppColors.violet,
                  onRefresh: () => _loadEvents(reset: true),
                  child: _EventsList(
                    events: _isSearching ? _searchResults : _events,
                    isSearching: _isSearching,
                    searchQuery: _searchCtrl.text,
                    loadingMore: _loadingMore,
                    scrollCtrl: _scrollCtrl,
                  ),
                ),
    );
  }
}

// ── Search + Filter bar ───────────────────────────────────────────────────────

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.controller,
    required this.onChanged,
    required this.selectedCategory,
    required this.onCategorySelected,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  static const _cats = [
    ('All', null),
    ('Music', 'music'),
    ('Arts', 'arts'),
    ('Food', 'food'),
    ('Sports', 'sports'),
    ('Tech', 'tech'),
    ('Comedy', 'comedy'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search events, venues, cities…',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.xs),
            itemCount: _cats.length,
            itemBuilder: (_, i) {
              final (label, value) = _cats[i];
              final selected = selectedCategory == value ||
                  (value == null && selectedCategory == null);
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => onCategorySelected(value),
                selectedColor: AppColors.violet.withAlpha(26),
                checkmarkColor: AppColors.violet,
                labelStyle: AppTypography.caption.copyWith(
                  color: selected ? AppColors.violet : AppColors.textMuted,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

// ── Events List ───────────────────────────────────────────────────────────────

class _EventsList extends StatelessWidget {
  const _EventsList({
    required this.events,
    required this.isSearching,
    required this.searchQuery,
    required this.loadingMore,
    required this.scrollCtrl,
  });
  final List<Event> events;
  final bool isSearching;
  final String searchQuery;
  final bool loadingMore;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return FtEmptyState(
        message: isSearching
            ? 'No events found for "$searchQuery".'
            : 'No events right now. Check back soon!',
        icon: Icons.event_busy_rounded,
      );
    }
    return ListView.separated(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: events.length + (loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        if (i == events.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return EventCard(event: events[i]);
      },
    );
  }
}

class _EventsListSkeleton extends StatelessWidget {
  const _EventsListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) =>
          const FtSkeleton(width: double.infinity, height: 260, borderRadius: 24),
    );
  }
}
