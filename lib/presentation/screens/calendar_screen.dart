import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/event_model.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    context.read<EventBloc>().add(const FetchEvents());
  }

  void _moveMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = DateTime(_month.year, _month.month, 1);
    });
  }

  void _today() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _selected = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Events Calendar'),
          actions: [
            TextButton(onPressed: _today, child: const Text('Today')),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<EventBloc, EventState>(
          builder: (context, state) {
            final events = state is EventLoaded ? state.events : <EventModel>[];
            return RefreshIndicator(
              onRefresh: () async {
                context.read<EventBloc>().add(const FetchEvents(forceRefresh: true));
                await context.read<EventBloc>().stream.firstWhere(
                    (value) => value is EventLoaded || value is EventError);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _monthCard(events)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                      child: Text(
                        DateFormat('EEEE, d MMMM').format(_selected),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  if (state is EventLoading || state is EventInitial)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state is EventError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyDay(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not refresh the calendar',
                        action: 'Try again',
                        onPressed: () => context.read<EventBloc>().add(
                            const FetchEvents(forceRefresh: true)),
                      ),
                    )
                  else
                    _dayList(events),
                ],
              ),
            );
          },
        ),
      );

  Widget _monthCard(List<EventModel> events) {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday % 7;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x100A0A14), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(children: [
        Row(children: [
          IconButton(
              tooltip: 'Previous month',
              onPressed: () => _moveMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
            child: Text(DateFormat('MMMM yyyy').format(_month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
              tooltip: 'Next month',
              onPressed: () => _moveMonth(1),
              icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              Expanded(
                child: Text(day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: .92,
          ),
          itemCount: leading + days,
          itemBuilder: (_, index) {
            if (index < leading) return const SizedBox.shrink();
            final date = DateTime(_month.year, _month.month, index - leading + 1);
            return _DayCell(
              date: date,
              selected: _sameDay(date, _selected),
              today: _sameDay(date, DateTime.now()),
              hasEvents: events.any((event) => _sameDay(_eventDate(event), date)),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selected = date);
              },
            );
          },
        ),
      ]),
    );
  }

  Widget _dayList(List<EventModel> events) {
    final selectedEvents = events
        .where((event) => _sameDay(_eventDate(event), _selected))
        .toList()
      ..sort((a, b) => _eventDate(a).compareTo(_eventDate(b)));
    if (selectedEvents.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyDay(
          icon: Icons.event_available_outlined,
          title: 'No events on this day',
          action: 'Browse upcoming events',
          onPressed: () => context.go('/'),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      sliver: SliverList.separated(
        itemCount: selectedEvents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _CalendarEventCard(event: selectedEvents[index]),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.selected, required this.today,
      required this.hasEvents, required this.onTap});
  final DateTime date;
  final bool selected;
  final bool today;
  final bool hasEvents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: DateFormat('EEEE, d MMMM yyyy').format(date),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: selected ? AppGradients.brand : null,
                border: today && !selected
                    ? Border.all(color: AppColors.purple, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${date.day}',
                    style: TextStyle(
                        color: selected ? Colors.white : AppColors.text,
                        fontWeight: selected || today ? FontWeight.w800 : FontWeight.w500)),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEvents
                        ? (selected ? Colors.white : AppColors.pink)
                        : Colors.transparent,
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final image = event.logo?.original?.url ?? event.logo?.url;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border)),
      child: InkWell(
        onTap: () => context.push('/event/${event.id}', extra: event),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 92,
                height: 92,
                child: image == null || image.isEmpty
                    ? Container(
                        decoration: const BoxDecoration(gradient: AppGradients.brand),
                        child: const Icon(Icons.event_rounded, color: Colors.white))
                    : CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(event.name.text, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.text,
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(DateFormat('h:mm a').format(_eventDate(event)),
                    style: const TextStyle(color: AppColors.purple,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(event.isOnlineEvent ? 'Online event' :
                    (event.venue?.name ?? event.venue?.address?.city ?? 'Venue TBA'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 8),
            Text(event.isFree ? 'Free' : 'Tickets',
                style: const TextStyle(color: AppColors.pink,
                    fontWeight: FontWeight.w800, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.icon, required this.title,
      required this.action, required this.onPressed});
  final IconData icon;
  final String title;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            TextButton(onPressed: onPressed, child: Text(action)),
          ]),
        ),
      );
}

DateTime _eventDate(EventModel event) =>
    DateTime.tryParse(event.start.local) ?? DateTime(1970);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
