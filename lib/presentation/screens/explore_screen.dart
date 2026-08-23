import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/event_discovery.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/discovery_preferences_repository.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';
import '../widgets/event_network_image.dart';
import '../widgets/save_event_button.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.savedEventsRepository,
    required this.preferencesRepository,
  });

  final SavedEventsRepository savedEventsRepository;
  final DiscoveryPreferencesRepository preferencesRepository;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  String? _category;
  String? _city;
  bool? _isFree;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    if (context.read<EventBloc>().state is EventInitial) {
      context.read<EventBloc>().add(const FetchEvents());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<EventModel> _filteredResults(List<EventModel> events) {
    final query = _search.text.trim();
    return filterExploreEvents(
      events,
      query: query,
      category: _category,
      city: _city,
      startDate: _startDate,
      endDate: _endDate,
      isFree: _isFree,
    );
  }

  void _submitSearch() {
    final query = _search.text.trim();
    if (query.isEmpty) {
      context.read<EventBloc>().add(const ClearFilters());
      return;
    }
    widget.preferencesRepository.rememberSearch(query);
    context.read<EventBloc>().add(SearchEvents(query: query));
  }

  void _applyFilters(List<EventModel> events) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final cities = events
            .map((event) => event.venue?.address?.city?.trim())
            .whereType<String>()
            .where((city) => city.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        return StatefulBuilder(
          builder: (context, setSheetState) {
            DateTime? start = _startDate;
            DateTime? end = _endDate;
            String? city = _city;
            bool? free = _isFree;
            String? category = _category;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    _FilterSection(
                      title: 'Date',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(
                            label: 'Any time',
                            selected: start == null && end == null,
                            onTap: () => setSheetState(() {
                              start = null;
                              end = null;
                            }),
                          ),
                          _Chip(
                            label: 'Today',
                            selected: start != null &&
                                end != null &&
                                start!.day == DateTime.now().day,
                            onTap: () => setSheetState(() {
                              final now = DateTime.now();
                              start = DateTime(now.year, now.month, now.day);
                              end = start!.add(const Duration(days: 1));
                            }),
                          ),
                          _Chip(
                            label: 'This weekend',
                            selected: start != null &&
                                end != null &&
                                end!.difference(start!).inDays <= 2,
                            onTap: () => setSheetState(() {
                              final weekend =
                                  nextWeekendStartForHarare(DateTime.now());
                              start = weekend;
                              end = weekend.add(const Duration(days: 2));
                            }),
                          ),
                          _Chip(
                            label: 'This month',
                            selected: start != null &&
                                end != null &&
                                end!.month == DateTime.now().month,
                            onTap: () => setSheetState(() {
                              final now = DateTime.now();
                              start = DateTime(now.year, now.month, 1);
                              end = DateTime(now.year, now.month + 1, 0);
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterSection(
                      title: 'Location',
                      child: DropdownButtonFormField<String?>(
                        initialValue: city,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'City'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Zimbabwe'),
                          ),
                          ...cities.map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          ),
                        ],
                        onChanged: (value) => setSheetState(() => city = value),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterSection(
                      title: 'Admission',
                      child: SegmentedButton<bool?>(
                        segments: const [
                          ButtonSegment(value: null, label: Text('All')),
                          ButtonSegment(value: true, label: Text('Free')),
                          ButtonSegment(value: false, label: Text('Paid')),
                        ],
                        selected: {free},
                        onSelectionChanged: (value) =>
                            setSheetState(() => free = value.first),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FilterSection(
                      title: 'Category',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CategoryChip(
                            label: 'All',
                            selected: category == null,
                            onTap: () => setSheetState(() => category = null),
                          ),
                          ...events
                              .map((event) => event.categoryId)
                              .whereType<String>()
                              .where((value) => value.trim().isNotEmpty)
                              .toSet()
                              .map(
                                (value) => _CategoryChip(
                                  label: value,
                                  selected: category == value,
                                  onTap: () =>
                                      setSheetState(() => category = value),
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _search.clear();
                              setState(() {
                                _category = null;
                                _city = null;
                                _isFree = null;
                                _startDate = null;
                                _endDate = null;
                              });
                              context
                                  .read<EventBloc>()
                                  .add(const ClearFilters());
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _city = city;
                                _isFree = free;
                                _category = category;
                                _startDate = start;
                                _endDate = end;
                              });
                              context.read<EventBloc>().add(
                                    ApplyFilters(
                                      city: city,
                                      isFree: free,
                                      startDate: start,
                                      endDate: end,
                                    ),
                                  );
                              Navigator.pop(sheetContext);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<EventBloc, EventState>(
          builder: (context, state) {
            final loadedEvents =
                state is EventLoaded ? state.events : <EventModel>[];
            final filtered = _filteredResults(loadedEvents);

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<EventBloc>()
                    .add(const FetchEvents(forceRefresh: true));
                await context.read<EventBloc>().stream.firstWhere(
                      (value) => value is EventLoaded || value is EventError,
                    );
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explore',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _search,
                                  onSubmitted: (_) => _submitSearch(),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Search events, artists or venues',
                                    prefixIcon: Icon(Icons.search_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.brand,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: IconButton(
                                  tooltip: 'Filter events',
                                  onPressed: () => _applyFilters(loadedEvents),
                                  color: Colors.white,
                                  icon: const Icon(Icons.tune_rounded),
                                ),
                              ),
                            ],
                          ),
                          if (widget.preferencesRepository.recentSearches
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 30,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.preferencesRepository
                                    .recentSearches.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, index) => ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(widget.preferencesRepository
                                      .recentSearches[index]),
                                  onPressed: () {
                                    _search.text = widget.preferencesRepository
                                        .recentSearches[index];
                                    _submitSearch();
                                  },
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: true, label: Text('List')),
                              ButtonSegment(value: false, label: Text('Map')),
                            ],
                            selected: {_showMap ? false : true},
                            onSelectionChanged: (selection) =>
                                setState(() => _showMap = !selection.first),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state is EventLoading || state is EventInitial)
                    const SliverToBoxAdapter(child: _Loading())
                  else if (state is EventError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _State(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load events',
                        detail: state.message,
                        onTap: () => context.read<EventBloc>().add(
                              const FetchEvents(forceRefresh: true),
                            ),
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _State(
                        icon: Icons.explore_outlined,
                        title: 'No results yet',
                        detail: 'Try another search, date, or city filter.',
                        onTap: () {
                          _search.clear();
                          setState(() {
                            _category = null;
                            _city = null;
                            _isFree = null;
                            _startDate = null;
                            _endDate = null;
                          });
                          context.read<EventBloc>().add(const ClearFilters());
                        },
                      ),
                    )
                  else if (_showMap)
                    SliverToBoxAdapter(
                      child: _MapPreview(
                        events: filtered,
                        savedEventsRepository: widget.savedEventsRepository,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, index) => _DiscoverCard(
                          event: filtered[index],
                          savedEventsRepository: widget.savedEventsRepository,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({
    required this.event,
    required this.savedEventsRepository,
  });

  final EventModel event;
  final SavedEventsRepository savedEventsRepository;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(event.start.local) ?? DateTime.now();
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/event/${event.id}', extra: event),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 110,
                  height: 98,
                  child: EventNetworkImage.forEvent(event),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pill(value: event.categoryLabel ?? event.categoryId),
                    const SizedBox(height: 8),
                    Text(
                      event.name.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${event.venue?.name ?? 'Venue'} • ${event.venue?.address?.city ?? 'Zimbabwe'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('EEE, d MMM • h:mm a').format(date),
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.isFree ? 'Free' : 'Paid',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SaveEventButton(
                          eventId: event.id,
                          repository: savedEventsRepository,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.events,
    required this.savedEventsRepository,
  });

  final List<EventModel> events;
  final SavedEventsRepository savedEventsRepository;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
      child: Column(
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    size: 42,
                    color: AppColors.purple,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${events.length} event${events.length == 1 ? '' : 's'} on map',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Map discovery is available in the dedicated map flow.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...events.take(3).map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DiscoverCard(
                    event: event,
                    savedEventsRepository: savedEventsRepository,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          (value ?? 'Event').toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.purple,
          ),
        ),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _State extends StatelessWidget {
  const _State({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              FilledButton.tonal(
                onPressed: onTap,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}
