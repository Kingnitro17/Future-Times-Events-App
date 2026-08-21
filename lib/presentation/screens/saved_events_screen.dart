import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../widgets/event_network_image.dart';
import '../widgets/save_event_button.dart';

class SavedEventsScreen extends StatelessWidget {
  const SavedEventsScreen(
      {super.key,
      required this.eventRepository,
      required this.savedEventsRepository});
  final EventRepository eventRepository;
  final SavedEventsRepository savedEventsRepository;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Saved Events')),
        body: ListenableBuilder(
            listenable: savedEventsRepository,
            builder: (context, _) {
              final ids = savedEventsRepository.ids;
              if (savedEventsRepository.isLoading) return const _Loading();
              if (ids.isEmpty) return const _Empty();
              return FutureBuilder<List<EventModel>>(
                future: eventRepository.getEventsByIds(ids),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _Loading();
                  }
                  if (snapshot.hasError) {
                    return _Error(onRetry: savedEventsRepository.load);
                  }
                  final events = snapshot.data ?? const [];
                  return RefreshIndicator(
                      onRefresh: savedEventsRepository.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _Card(
                            event: events[index],
                            repository: savedEventsRepository),
                      ));
                },
              );
            }),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.event, required this.repository});
  final EventModel event;
  final SavedEventsRepository repository;
  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(event.start.local) ?? DateTime.now();
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border)),
      child: InkWell(
          onTap: () => context.push('/event/${event.id}', extra: event),
          child: Row(children: [
            SizedBox(
                width: 118,
                height: 118,
                child: EventNetworkImage.forEvent(event)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(event.categoryId?.toUpperCase() ?? 'EVENT',
                      style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8)),
                  const SizedBox(height: 6),
                  Text(event.name.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          height: 1.15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(DateFormat('EEE, d MMM · h:mm a').format(start),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(event.venue?.name ?? 'Venue TBA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ])),
            SaveEventButton(eventId: event.id, repository: repository),
            const SizedBox(width: 4),
          ])),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
          height: 118,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20))));
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bookmark_add_outlined,
                size: 64, color: AppColors.purple),
            const SizedBox(height: 18),
            Text('Nothing saved yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Save events you love and find them here anytime.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Discover Events')),
          ])));
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined,
            size: 54, color: AppColors.textMuted),
        const SizedBox(height: 12),
        const Text('Saved events are unavailable.'),
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ]));
}
