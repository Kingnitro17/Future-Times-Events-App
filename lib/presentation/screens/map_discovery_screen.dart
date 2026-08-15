import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';

class MapDiscoveryScreen extends StatefulWidget {
  const MapDiscoveryScreen({super.key});
  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    if (context.read<EventBloc>().state is EventInitial) {
      context.read<EventBloc>().add(const FetchEvents());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore the map')),
      body: BlocBuilder<EventBloc, EventState>(builder: (context, state) {
        if (state is EventLoading || state is EventInitial)
          return const Center(child: CircularProgressIndicator());
        if (state is EventError)
          return _Message(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load events',
              detail: state.message,
              onRetry: () => context
                  .read<EventBloc>()
                  .add(const FetchEvents(forceRefresh: true)));
        final events = (state as EventLoaded).events;
        final located = events
            .where((event) =>
                double.tryParse(event.venue?.latitude ?? '') != null &&
                double.tryParse(event.venue?.longitude ?? '') != null)
            .toList();
        if (located.isEmpty)
          return const _Message(
              icon: Icons.map_outlined,
              title: 'No mapped events yet',
              detail:
                  'Events with verified venue coordinates will appear here.');
        final first = located.first;
        final center = LatLng(double.parse(first.venue!.latitude!),
            double.parse(first.venue!.longitude!));
        return FlutterMap(
          options: MapOptions(
              initialCenter: center,
              initialZoom: 11,
              interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate)),
          children: [
            TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'za.co.futuretimes.events'),
            MarkerLayer(
                markers: located
                    .map((event) => Marker(
                          point: LatLng(double.parse(event.venue!.latitude!),
                              double.parse(event.venue!.longitude!)),
                          width: 52,
                          height: 52,
                          child: Semantics(
                            button: true,
                            label: 'Open ${event.name.text}',
                            child: IconButton.filled(
                                onPressed: () => context
                                    .push('/event/${event.id}', extra: event),
                                icon: const Icon(Icons.location_on_rounded),
                                style: IconButton.styleFrom(
                                    backgroundColor: AppColors.purple,
                                    foregroundColor: Colors.white)),
                          ),
                        ))
                    .toList()),
          ],
        );
      }),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.icon,
      required this.title,
      required this.detail,
      this.onRetry});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                  onPressed: onRetry, child: const Text('Try again'))
            ],
          ])));
}
