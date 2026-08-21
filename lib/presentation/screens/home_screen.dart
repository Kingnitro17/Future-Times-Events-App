import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';
import '../widgets/event_network_image.dart';
import '../widgets/save_event_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.savedEventsRepository});
  final SavedEventsRepository savedEventsRepository;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String? _category;

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

  void _select(String? value) {
    HapticFeedback.selectionClick();
    setState(() => _category = value);
    context.read<EventBloc>().add(FilterByCategory(
        categoryId: value ?? '',
        categoryName: value == null ? 'All' : _label(value)));
  }

  void _clear() {
    _search.clear();
    setState(() => _category = null);
    context.read<EventBloc>().add(const ClearFilters());
  }

  void _filters() => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Filter events',
                      style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 18),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.pop(sheet);
                        context
                            .read<EventBloc>()
                            .add(const ApplyFilters(isFree: true));
                      },
                      icon: const Icon(Icons.local_activity_outlined),
                      label: const Text('Free events'))),
              const SizedBox(height: 10),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheet);
                        _clear();
                      },
                      child: const Text('Clear all filters'))),
            ]),
          ));

  void _allCategories(List<String> values) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Wrap(spacing: 10, runSpacing: 10, children: [
              ActionChip(
                  label: const Text('All'),
                  onPressed: () {
                    Navigator.pop(sheet);
                    _select(null);
                  }),
              for (final value in values)
                ActionChip(
                    avatar: Icon(_icon(value), size: 18),
                    label: Text(_label(value)),
                    onPressed: () {
                      Navigator.pop(sheet);
                      _select(value);
                    }),
            ]),
          ));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<EventBloc, EventState>(builder: (context, state) {
            final events = state is EventLoaded ? state.events : <EventModel>[];
            final categories = events
                .map((e) => e.categoryId)
                .whereType<String>()
                .where((v) => v.isNotEmpty)
                .toSet()
                .toList();
            final topPicks = events.where((event) => event.featured).toList();
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<EventBloc>()
                    .add(const FetchEvents(forceRefresh: true));
                await context.read<EventBloc>().stream.firstWhere(
                    (value) => value is EventLoaded || value is EventError);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _Header(events: events)),
                  SliverToBoxAdapter(
                      child: _SearchBar(
                          controller: _search,
                          onSearch: (value) => context
                              .read<EventBloc>()
                              .add(SearchEvents(query: value.trim())),
                          onFilter: _filters)),
                  SliverToBoxAdapter(
                      child: _Section('Categories',
                          onSeeAll: categories.isEmpty
                              ? null
                              : () => _allCategories(categories))),
                  SliverToBoxAdapter(
                      child: _Categories(
                          values: categories,
                          selected: _category,
                          onSelected: _select)),
                  if (state is EventLoading || state is EventInitial)
                    const SliverToBoxAdapter(child: _Loading())
                  else if (state is EventError)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: _State(
                            icon: Icons.cloud_off_outlined,
                            title: "We couldn't load events.",
                            detail: 'Check your connection and try again.',
                            action: 'Try Again',
                            onTap: () => context
                                .read<EventBloc>()
                                .add(const FetchEvents(forceRefresh: true))))
                  else if (events.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: _State(
                            icon: Icons.event_busy_outlined,
                            title: 'No events found',
                            detail: 'Try another search or reset your filters.',
                            action: 'Browse all events',
                            onTap: _clear))
                  else ...[
                    const SliverToBoxAdapter(child: _Section('Top Picks')),
                    SliverToBoxAdapter(
                        child: _FeaturedRail(
                            events: topPicks.isEmpty
                                ? events.take(6).toList()
                                : topPicks,
                            savedEventsRepository:
                                widget.savedEventsRepository)),
                    const SliverToBoxAdapter(
                        child: _Section('Upcoming Events')),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const Divider(height: 17),
                        itemBuilder: (_, index) => _Upcoming(
                            event: events[index],
                            savedEventsRepository:
                                widget.savedEventsRepository),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.events});
  final List<EventModel> events;
  @override
  Widget build(BuildContext context) {
    final cities = events
        .map((e) => e.venue?.address?.city)
        .whereType<String>()
        .where((v) => v.isNotEmpty);
    final place = cities.isEmpty ? 'Zimbabwe' : '${cities.first}, Zimbabwe';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
                gradient: AppGradients.brand, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 21)),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Location',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.location_on_rounded,
                size: 17, color: AppColors.pink),
            const SizedBox(width: 3),
            Flexible(
                child: Text(place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700))),
          ]),
        ])),
        _HeaderButton(
            icon: Icons.calendar_month_outlined,
            tooltip: 'Events calendar',
            onTap: () => context.push('/calendar')),
        const SizedBox(width: 8),
        _HeaderButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Profile',
            onTap: () => context.go('/profile')),
      ]),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: IconButton(onPressed: onTap, tooltip: tooltip, icon: Icon(icon)));
}

class _SearchBar extends StatelessWidget {
  const _SearchBar(
      {required this.controller,
      required this.onSearch,
      required this.onFilter});
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilter;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          Expanded(
              child: SizedBox(
                  height: 52,
                  child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: onSearch,
                      decoration: const InputDecoration(
                          hintText: 'Search events, artists or venues',
                          prefixIcon: Icon(Icons.search_rounded),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12))))),
          const SizedBox(width: 10),
          Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x287222E3),
                        blurRadius: 14,
                        offset: Offset(0, 6))
                  ]),
              child: IconButton(
                  tooltip: 'Filter events',
                  onPressed: onFilter,
                  color: Colors.white,
                  icon: const Icon(Icons.tune_rounded))),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section(this.title, {this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 12),
      child: Row(children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ]));
}

class _Categories extends StatelessWidget {
  const _Categories(
      {required this.values, required this.selected, required this.onSelected});
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 91,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          final value = index == 0 ? null : values[index - 1];
          final active = value == selected;
          return InkWell(
              onTap: () => onSelected(value),
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                  width: 62,
                  child: Column(children: [
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                            gradient: active ? AppGradients.brand : null,
                            color: active ? null : AppColors.surface,
                            shape: BoxShape.circle,
                            border: active
                                ? null
                                : Border.all(color: AppColors.border),
                            boxShadow: active
                                ? const [
                                    BoxShadow(
                                        color: Color(0x307222E3),
                                        blurRadius: 12,
                                        offset: Offset(0, 5))
                                  ]
                                : null),
                        child: Icon(_icon(value),
                            color: active ? Colors.white : AppColors.purple)),
                    const SizedBox(height: 7),
                    Text(value == null ? 'All' : _label(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: active ? AppColors.purple : AppColors.text,
                            fontSize: 11,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w600)),
                  ])));
        },
      ));
}

class _FeaturedRail extends StatelessWidget {
  const _FeaturedRail(
      {required this.events, required this.savedEventsRepository});
  final List<EventModel> events;
  final SavedEventsRepository savedEventsRepository;
  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * .78).clamp(280.0, 328.0);
    return SizedBox(
        height: 334,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, index) => SizedBox(
              width: width,
              child: _Featured(
                  event: events[index],
                  savedEventsRepository: savedEventsRepository)),
        ));
  }
}

class _Featured extends StatelessWidget {
  const _Featured({required this.event, required this.savedEventsRepository});
  final EventModel event;
  final SavedEventsRepository savedEventsRepository;
  @override
  Widget build(BuildContext context) {
    final date = _date(event);
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border)),
      child: InkWell(
          onTap: () => context.push('/event/${event.id}', extra: event),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              _Artwork(event: event, height: 190),
              Positioned(
                  left: 12, top: 12, child: _Pill(value: event.categoryId)),
              Positioned(
                  right: 9,
                  top: 9,
                  child: SaveEventButton(
                      eventId: event.id,
                      repository: savedEventsRepository,
                      onSurface: true)),
              Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                          color: const Color(0xE6141420),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                          DateFormat('dd\nMMM').format(date).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              height: 1.05,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)))),
            ]),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.name.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 17,
                                  height: 1.18,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          _Meta(
                              icon: Icons.location_on_outlined,
                              text: _location(event)),
                          const SizedBox(height: 5),
                          _Meta(
                              icon: Icons.schedule_rounded,
                              text: DateFormat('EEE, d MMM • h:mm a')
                                  .format(date)),
                          const SizedBox(height: 8),
                          Text(_price(event),
                              style: const TextStyle(
                                  color: AppColors.purple,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                        ]))),
          ])),
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.event, required this.savedEventsRepository});
  final EventModel event;
  final SavedEventsRepository savedEventsRepository;
  @override
  Widget build(BuildContext context) {
    final date = _date(event);
    return InkWell(
      onTap: () => context.push('/event/${event.id}', extra: event),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                    width: 108, child: _Artwork(event: event, height: 94))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _Pill(value: event.categoryId, compact: true),
                  const SizedBox(height: 6),
                  Text(event.name.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          height: 1.18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _Meta(
                      icon: Icons.calendar_today_outlined,
                      text: DateFormat('EEE, d MMM • h:mm a').format(date)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                        child: _Meta(
                            icon: Icons.location_on_outlined,
                            text: _location(event))),
                    const SizedBox(width: 8),
                    Text(_price(event),
                        style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    SaveEventButton(
                        eventId: event.id, repository: savedEventsRepository),
                  ]),
                ])),
          ])),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.event, required this.height});
  final EventModel event;
  final double height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: EventNetworkImage.forEvent(event),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.value, this.compact = false});
  final String? value;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
          color: compact ? const Color(0xFFF0E7FF) : const Color(0xE6FF55C2),
          borderRadius: BorderRadius.circular(999)),
      child: Text(_label(value ?? 'Event').toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: compact ? AppColors.purple : Colors.white,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w800)));
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 15, color: AppColors.purple),
        const SizedBox(width: 5),
        Expanded(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12))),
      ]);
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.surfaceMuted,
        highlightColor: Colors.white,
        child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: _Skeleton(width: 110, height: 22)),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _Skeleton(
                      width: double.infinity, height: 320, radius: 20)),
              Padding(
                  padding: EdgeInsets.fromLTRB(16, 22, 16, 12),
                  child: _Skeleton(width: 150, height: 22)),
              Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _Skeleton(
                      width: double.infinity, height: 94, radius: 16)),
            ]),
      );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height, this.radius = 8});
  final double width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(radius)));
}

class _State extends StatelessWidget {
  const _State(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.action,
      required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 58, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.tonal(onPressed: onTap, child: Text(action)),
          ])));
}

DateTime _date(EventModel event) =>
    DateTime.tryParse(event.start.local) ?? DateTime.now();
String _location(EventModel event) => event.isOnlineEvent
    ? 'Online event'
    : event.venue?.name ?? event.venue?.address?.city ?? 'Venue TBA';
String _price(EventModel event) {
  if (event.isFree) return 'Free';
  final tickets =
      event.ticketClasses.where((ticket) => !ticket.hidden).toList();
  if (tickets.isEmpty) return 'View event';
  if (tickets.every((ticket) => ticket.free)) return 'Free';
  final costs = tickets
      .map((ticket) => ticket.cost)
      .whereType<EventCost>()
      .toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return costs.isEmpty ? 'Tickets' : 'From ${costs.first.display}';
}

String _label(String value) => value
    .replaceAll(RegExp(r'[_-]+'), ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
IconData _icon(String? value) {
  final v = value?.toLowerCase() ?? '';
  if (v.contains('music')) return Icons.music_note_rounded;
  if (v.contains('sport')) return Icons.sports_soccer_rounded;
  if (v.contains('night')) return Icons.local_bar_outlined;
  if (v.contains('business')) return Icons.business_center_outlined;
  if (v.contains('art') || v.contains('culture')) return Icons.palette_outlined;
  if (v.contains('family')) return Icons.family_restroom_rounded;
  if (v.contains('food')) return Icons.restaurant_rounded;
  return value == null ? Icons.grid_view_rounded : Icons.celebration_outlined;
}
