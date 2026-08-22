import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/utils/event_discovery.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/discovery_preferences_repository.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';
import '../widgets/event_network_image.dart';
import '../widgets/save_event_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authRepository,
    required this.savedEventsRepository,
    required this.preferencesRepository,
  });

  final AuthRepository authRepository;
  final SavedEventsRepository savedEventsRepository;
  final DiscoveryPreferencesRepository preferencesRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.preferencesRepository.addListener(_preferencesChanged);
    if (context.read<EventBloc>().state is EventInitial) {
      context.read<EventBloc>().add(const FetchEvents());
    }
  }

  void _preferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.preferencesRepository.removeListener(_preferencesChanged);
    super.dispose();
  }

  List<EventModel> _recommendedEvents(List<EventModel> events) {
    final preferredCity = widget.preferencesRepository.city;
    final interests = widget.preferencesRepository.interests;
    return rankHomeEvents(
      events,
      preferredCity: preferredCity,
      interests: interests,
    );
  }

  List<EventModel> _futureSoon(List<EventModel> events) {
    final now = DateTime.now();
    final windowEnd = now.add(const Duration(days: 21));
    return events
        .where((event) => _eventDate(event).isAfter(now))
        .where((event) => _eventDate(event).isBefore(windowEnd))
        .toList();
  }

  List<EventModel> _weekendEvents(List<EventModel> events) {
    final weekendStart = nextWeekendStartForHarare(DateTime.now());
    final weekendEnd = weekendStart.add(const Duration(days: 2));
    return events.where((event) {
      final date = _eventDate(event);
      return !date.isBefore(weekendStart) && !date.isAfter(weekendEnd);
    }).toList();
  }

  List<EventModel> _freeEvents(List<EventModel> events) =>
      events.where((event) => event.isFree).take(5).toList();

  List<EventModel> _savedForLater(List<EventModel> events) {
    if (!widget.authRepository.isSignedIn) return const [];
    final saved = widget.savedEventsRepository.ids;
    return events
        .where((event) => saved.contains(event.id))
        .where((event) => _eventDate(event).isAfter(DateTime.now()))
        .take(3)
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<EventBloc, EventState>(
            builder: (context, state) {
              final loadedEvents =
                  state is EventLoaded ? state.events : <EventModel>[];
              final recommended = _recommendedEvents(loadedEvents);
              final soon = _futureSoon(recommended);
              final weekend = _weekendEvents(recommended);
              final free = _freeEvents(recommended);
              final saved = _savedForLater(recommended);

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
                      child: _HomeHeader(
                        authRepository: widget.authRepository,
                        preferredCity: widget.preferencesRepository.city,
                      ),
                    ),
                    if (state is EventLoading || state is EventInitial)
                      const SliverToBoxAdapter(child: _Loading())
                    else if (state is EventError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _State(
                          icon: Icons.cloud_off_outlined,
                          title: "We couldn't load your feed.",
                          detail: 'Check your connection and try again.',
                          action: 'Try again',
                          onTap: () => context.read<EventBloc>().add(
                                const FetchEvents(forceRefresh: true),
                              ),
                        ),
                      )
                    else if (recommended.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _State(
                          icon: Icons.event_busy_outlined,
                          title: 'Nothing new right now',
                          detail:
                              'Check back soon for fresh events in Harare and beyond.',
                          action: 'Refresh',
                          onTap: () => context.read<EventBloc>().add(
                                const FetchEvents(forceRefresh: true),
                              ),
                        ),
                      )
                    else ...[
                      if (recommended.isNotEmpty) ...[
                        const SliverToBoxAdapter(child: _Section('For You')),
                        SliverToBoxAdapter(
                          child: _FeaturedRail(
                            events: recommended.take(5).toList(),
                            savedEventsRepository: widget.savedEventsRepository,
                          ),
                        ),
                      ],
                      if (soon.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: _Section('Happening Soon'),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          sliver: SliverList.separated(
                            itemCount: soon.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) => _Upcoming(
                              event: soon[index],
                              savedEventsRepository:
                                  widget.savedEventsRepository,
                            ),
                          ),
                        ),
                      ],
                      if (weekend.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: _Section('This Weekend'),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          sliver: SliverList.separated(
                            itemCount: weekend.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) => _Upcoming(
                              event: weekend[index],
                              savedEventsRepository:
                                  widget.savedEventsRepository,
                            ),
                          ),
                        ),
                      ],
                      if (free.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: _Section('Free Events'),
                        ),
                        SliverToBoxAdapter(
                          child: _FeaturedRail(
                            events: free,
                            savedEventsRepository: widget.savedEventsRepository,
                          ),
                        ),
                      ],
                      if (saved.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: _Section('Saved for later'),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          sliver: SliverList.separated(
                            itemCount: saved.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) => _Upcoming(
                              event: saved[index],
                              savedEventsRepository:
                                  widget.savedEventsRepository,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.authRepository,
    required this.preferredCity,
  });

  final AuthRepository authRepository;
  final String preferredCity;

  @override
  Widget build(BuildContext context) {
    final displayName = authRepository.user?.email?.split('@').first ?? '';
    final greeting = displayName.isEmpty
        ? "Discover what's happening"
        : 'Hi ${_displayName(displayName)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: AppGradients.brand,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: AppColors.purple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      preferredCity.isEmpty
                          ? 'Harare, Zimbabwe'
                          : '$preferredCity, Zimbabwe',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _HeaderButton(
            icon: Icons.calendar_month_outlined,
            tooltip: 'Calendar',
            onTap: () => context.push('/calendar'),
          ),
          const SizedBox(width: 8),
          _HeaderButton(
            icon: Icons.search_rounded,
            tooltip: 'Explore events',
            onTap: () => context.push('/explore'),
          ),
        ],
      ),
    );
  }
}

String _displayName(String emailLocal) {
  final cleaned = emailLocal.split(RegExp(r'[._-]')).first;
  if (cleaned.isEmpty) return 'there';
  return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: Icon(icon),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
}

class _FeaturedRail extends StatelessWidget {
  const _FeaturedRail({
    required this.events,
    required this.savedEventsRepository,
  });

  final List<EventModel> events;
  final SavedEventsRepository savedEventsRepository;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.78).clamp(280.0, 340.0);
    return SizedBox(
      height: 330,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) => SizedBox(
          width: width,
          child: _Featured(
            event: events[index],
            savedEventsRepository: savedEventsRepository,
          ),
        ),
      ),
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured({
    required this.event,
    required this.savedEventsRepository,
  });

  final EventModel event;
  final SavedEventsRepository savedEventsRepository;

  @override
  Widget build(BuildContext context) {
    final date = _eventDate(event);
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => context.push('/event/${event.id}', extra: event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _Artwork(event: event, height: 190),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _Pill(value: event.categoryLabel ?? event.categoryId),
                ),
                Positioned(
                  right: 9,
                  top: 9,
                  child: SaveEventButton(
                    eventId: event.id,
                    repository: savedEventsRepository,
                    onSurface: true,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _Meta(
                      icon: Icons.location_on_outlined,
                      text: event.venue?.address?.city ?? 'Harare',
                    ),
                    const SizedBox(height: 5),
                    _Meta(
                      icon: Icons.schedule_rounded,
                      text: DateFormat('EEE, d MMM • h:mm a').format(date),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.isFree ? 'Free' : 'Paid',
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({
    required this.event,
    required this.savedEventsRepository,
  });

  final EventModel event;
  final SavedEventsRepository savedEventsRepository;

  @override
  Widget build(BuildContext context) {
    final date = _eventDate(event);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
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
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 104,
                  height: 92,
                  child: _Artwork(event: event, height: 92),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pill(
                      value: event.categoryLabel ?? event.categoryId,
                      compact: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.name.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        height: 1.18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _Meta(
                      icon: Icons.calendar_today_outlined,
                      text: DateFormat('EEE, d MMM • h:mm a').format(date),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: _Meta(
                            icon: Icons.location_on_outlined,
                            text: event.venue?.address?.city ?? 'Harare',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.isFree ? 'Free' : 'Paid',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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

class _Artwork extends StatelessWidget {
  const _Artwork({required this.event, required this.height});

  final EventModel event;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: EventNetworkImage.forEvent(event),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.value, this.compact = false});

  final String? value;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: compact ? const Color(0xFFF0E7FF) : const Color(0xE6FF55C2),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          (value ?? 'Event').toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: compact ? AppColors.purple : Colors.white,
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.purple),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String action;
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
              FilledButton.tonal(onPressed: onTap, child: Text(action)),
            ],
          ),
        ),
      );
}

DateTime _eventDate(EventModel event) {
  final local = DateTime.tryParse(event.start.local);
  if (local != null) return local;
  return DateTime.tryParse(event.start.utc) ?? DateTime.now();
}
