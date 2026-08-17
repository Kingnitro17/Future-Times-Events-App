import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/event_model.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
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

  void _selectCategory(String? value) {
    setState(() => _category = value);
    context.read<EventBloc>().add(FilterByCategory(
        categoryId: value ?? '', categoryName: _label(value ?? 'All')));
  }

  void _showFilters() => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Find your kind of event',
                    style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(sheetContext);
                context.read<EventBloc>().add(const ApplyFilters(isFree: true));
              },
              icon: const Icon(Icons.local_activity_outlined),
              label: const Text('Free events'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                setState(() => _category = null);
                _search.clear();
                context.read<EventBloc>().add(const ClearFilters());
              },
              child: const Text('Clear filters'),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: BlocBuilder<EventBloc, EventState>(builder: (context, state) {
            final events = state is EventLoaded ? state.events : <EventModel>[];
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
                  SliverToBoxAdapter(child: _header(events)),
                  if (state is EventLoading || state is EventInitial)
                    const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()))
                  else if (state is EventError)
                    SliverFillRemaining(
                        child: _StateMessage(
                            title: 'Could not load events',
                            detail: state.message,
                            onRetry: () => context
                                .read<EventBloc>()
                                .add(const FetchEvents(forceRefresh: true))))
                  else if (events.isEmpty)
                    const SliverFillRemaining(
                        child: _StateMessage(
                            title: 'No events found',
                            detail:
                                'Try another search or clear your filters.'))
                  else ...[
                    const SliverToBoxAdapter(
                        child: _SectionTitle('Upcoming Events')),
                    SliverToBoxAdapter(child: _upcoming(events)),
                    const SliverToBoxAdapter(
                        child: _SectionTitle('More to explore')),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      sliver: SliverList.separated(
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, index) =>
                            _NearbyCard(event: events[index]),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      );

  Widget _header(List<EventModel> events) {
    final cities = events
        .map((e) => e.venue?.address?.city)
        .whereType<String>()
        .where((e) => e.isNotEmpty);
    final categories = events
        .map((e) => e.categoryId)
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .take(5)
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Location',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_rounded,
                    size: 18, color: AppColors.pink),
                const SizedBox(width: 4),
                Flexible(
                    child: Text(
                        cities.isEmpty ? 'Future Times Events' : cities.first,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700))),
              ]),
            ]),
          ),
          Container(
            decoration: const BoxDecoration(
                color: AppColors.surfaceMuted, shape: BoxShape.circle),
            child: IconButton(
                tooltip: 'Notifications',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications.'))),
                icon: const Icon(Icons.notifications_none_rounded)),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
                color: AppColors.surfaceMuted, shape: BoxShape.circle),
            child: IconButton(
                tooltip: 'Events calendar',
                onPressed: () => context.push('/calendar'),
                icon: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.purple)),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => context
                  .read<EventBloc>()
                  .add(SearchEvents(query: value.trim())),
              decoration: const InputDecoration(
                  hintText: 'Search events, venues',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(15)),
            child: IconButton(
                tooltip: 'Filter events',
                color: Colors.white,
                onPressed: _showFilters,
                icon: const Icon(Icons.tune_rounded)),
          ),
        ]),
        const SizedBox(height: 20),
        const _SectionTitle('Categories', flush: true),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 17),
            itemBuilder: (_, index) {
              final value = index == 0 ? null : categories[index - 1];
              return _Category(
                  label: value == null ? 'All' : _label(value),
                  icon: _icon(value),
                  selected: value == _category,
                  onTap: () => _selectCategory(value));
            },
          ),
        ),
      ]),
    );
  }

  Widget _upcoming(List<EventModel> events) => SizedBox(
        height: 254,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, index) => _UpcomingCard(event: events[index]),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.flush = false});
  final String text;
  final bool flush;
  @override
  Widget build(BuildContext context) => Padding(
      padding:
          flush ? EdgeInsets.zero : const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge));
}

class _Category extends StatelessWidget {
  const _Category(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
          width: 68,
          child: Column(children: [
            AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    gradient: selected ? AppGradients.brand : null,
                    color: selected ? null : AppColors.surfaceMuted,
                    shape: BoxShape.circle),
                child: Icon(icon,
                    color: selected ? Colors.white : AppColors.purple)),
            const SizedBox(height: 7),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? AppColors.purple : AppColors.text,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ])));
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.event});
  final EventModel event;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(event.start.local);
    return InkWell(
      onTap: () => context.push('/event/${event.id}', extra: event),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 274,
        padding: const EdgeInsets.all(8),
        decoration: _cardDecoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _EventImage(event: event, height: 132),
          const SizedBox(height: 10),
          Text(event.name.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Row(children: [
            const Icon(Icons.location_on_rounded,
                size: 14, color: AppColors.pink),
            const SizedBox(width: 3),
            Expanded(
                child: Text(_location(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11))),
            const Icon(Icons.schedule_rounded,
                size: 14, color: AppColors.purple),
            const SizedBox(width: 3),
            Text(date == null ? 'TBA' : DateFormat('MMM d').format(date),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
          const Spacer(),
          Text(event.isFree ? 'Free' : 'View tickets',
              style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.event});
  final EventModel event;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(event.start.local);
    return InkWell(
      onTap: () => context.push('/event/${event.id}', extra: event),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 116,
        padding: const EdgeInsets.all(8),
        decoration: _cardDecoration,
        child: Row(children: [
          SizedBox(width: 112, child: _EventImage(event: event, height: 100)),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(event.name.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(date == null
                    ? 'Date TBA'
                    : DateFormat('EEE, MMM d • h:mm a').format(date)),
                const SizedBox(height: 4),
                Text(_location(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.event, required this.height});
  final EventModel event;
  final double height;
  @override
  Widget build(BuildContext context) {
    final url = event.logo?.original?.url ?? event.logo?.url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        child: url == null || url.isEmpty
            ? Container(
                decoration: const BoxDecoration(gradient: AppGradients.brand),
                child: const Center(
                    child: Icon(Icons.event_rounded,
                        color: Colors.white, size: 38)))
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceMuted,
                    child: const Icon(Icons.event_rounded,
                        color: AppColors.purple))),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage(
      {required this.title, required this.detail, this.onRetry});
  final String title;
  final String detail;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.event_busy_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                  onPressed: onRetry, child: const Text('Try again'))
            ]
          ])));
}

final _cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(color: Color(0x120A0A14), blurRadius: 18, offset: Offset(0, 7))
    ]);

String _label(String value) => value
    .replaceAll(RegExp(r'[_-]+'), ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

IconData _icon(String? value) {
  final v = value?.toLowerCase() ?? '';
  if (v.contains('music')) return Icons.music_note_rounded;
  if (v.contains('art')) return Icons.palette_outlined;
  if (v.contains('business')) return Icons.business_center_outlined;
  if (v.contains('sport')) return Icons.sports_soccer_rounded;
  if (v.contains('food')) return Icons.restaurant_rounded;
  if (v.contains('fashion')) return Icons.checkroom_rounded;
  if (v.contains('game')) return Icons.sports_esports_rounded;
  return value == null ? Icons.grid_view_rounded : Icons.celebration_outlined;
}

String _location(EventModel event) => event.isOnlineEvent
    ? 'Online event'
    : event.venue?.address?.city ?? event.venue?.name ?? 'Venue TBA';
