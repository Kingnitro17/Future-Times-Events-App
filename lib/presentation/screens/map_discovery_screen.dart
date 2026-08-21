import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';
import '../widgets/event_network_image.dart';
import '../widgets/save_event_button.dart';

class MapDiscoveryScreen extends StatefulWidget {
  const MapDiscoveryScreen({super.key, required this.savedEventsRepository});
  final SavedEventsRepository savedEventsRepository;

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen>
    with AutomaticKeepAliveClientMixin {
  final _mapController = MapController();
  final _cards = PageController(viewportFraction: .82);
  String? _city;
  String? _selectedId;
  LatLng? _userLocation;
  bool _locating = false;
  String? _locationMessage;
  bool _mapReady = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (context.read<EventBloc>().state is EventInitial) {
      context.read<EventBloc>().add(const FetchEvents());
    }
  }

  @override
  void dispose() {
    _cards.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
    HapticFeedback.selectionClick();
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationMessage =
            'Location services are off. You can still browse by city.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationMessage = permission ==
                LocationPermission.deniedForever
            ? 'Location is blocked in Settings. Browse by city or enable it there.'
            : 'Location was not allowed. Browse any city instead.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _city = null;
        _locationMessage =
            'Showing events near you · accuracy about ${position.accuracy.round()} m';
      });
      _mapController.move(_userLocation!, 12);
    } on TimeoutException {
      if (mounted) {
        setState(() => _locationMessage =
            'Location took too long. Try again or choose a city.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationMessage =
            'We could not get your location. Choose a city to keep exploring.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _chooseCity(String? value, List<EventModel> events) {
    HapticFeedback.selectionClick();
    setState(() {
      _city = value;
      _userLocation = null;
      _locationMessage = null;
      _selectedId = null;
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fit(_filtered(events)));
  }

  void _fit(List<EventModel> events) {
    if (!_mapReady || events.isEmpty) return;
    final points = events.map(_point).whereType<LatLng>().toList();
    if (points.length == 1) {
      _mapController.move(points.first, 12.5);
    } else if (points.isNotEmpty) {
      _mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(54, 140, 54, 250),
        maxZoom: 13,
      ));
    }
  }

  void _select(EventModel event, List<EventModel> filtered,
      {bool fromCard = false}) {
    final index = filtered.indexWhere((value) => value.id == event.id);
    if (index < 0) return;
    setState(() => _selectedId = event.id);
    final point = _point(event);
    if (point != null) _mapController.move(point, 13.2);
    if (!fromCard && _cards.hasClients) {
      _cards.animateToPage(index,
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    }
  }

  List<EventModel> _filtered(List<EventModel> events) {
    final located = events.where((event) => _point(event) != null).toList();
    if (_city == null) return located;
    return located
        .where((event) => event.venue?.address?.city == _city)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: BlocBuilder<EventBloc, EventState>(builder: (context, state) {
        if (state is EventLoading || state is EventInitial) {
          return const _MapLoading();
        }
        if (state is EventError) {
          return _Message(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load the event map',
            detail: state.message,
            onRetry: () => context
                .read<EventBloc>()
                .add(const FetchEvents(forceRefresh: true)),
          );
        }
        final all = (state as EventLoaded).events;
        final located = all.where((event) => _point(event) != null).toList();
        if (located.isEmpty) {
          return const _Message(
            icon: Icons.map_outlined,
            title: 'No events in this area',
            detail: 'Published events with verified coordinates appear here.',
          );
        }
        final filtered = _filtered(all);
        final cities = located
            .map((event) => event.venue?.address?.city?.trim())
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        return Stack(children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _point(located.first)!,
              initialZoom: 10,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                _mapReady = true;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _fit(filtered));
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'za.co.futuretimes.events',
              ),
              MarkerLayer(markers: [
                if (_userLocation != null)
                  Marker(
                      point: _userLocation!,
                      width: 34,
                      height: 34,
                      child: const _UserMarker()),
                for (final event in filtered)
                  Marker(
                    point: _point(event)!,
                    width: _selectedId == event.id ? 58 : 46,
                    height: _selectedId == event.id ? 58 : 46,
                    child: _EventMarker(
                      selected: _selectedId == event.id,
                      label: event.name.text,
                      onTap: () => _select(event, filtered),
                    ),
                  ),
              ]),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 12,
            right: 12,
            child: _MapFilters(
              cities: cities,
              selectedCity: _city,
              myLocation: _userLocation != null,
              locating: _locating,
              message: _locationMessage,
              eventCount: filtered.length,
              onLocation: _useMyLocation,
              onCity: (value) => _chooseCity(value, all),
            ),
          ),
          if (filtered.isEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 34,
              child: _Glass(
                child: Row(children: [
                  const Icon(Icons.search_off_rounded, color: AppColors.purple),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text(
                          'No events in this city yet. Try another area.')),
                  TextButton(
                      onPressed: () => _chooseCity(null, all),
                      child: const Text('All')),
                ]),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              height: 154,
              child: PageView.builder(
                controller: _cards,
                itemCount: filtered.length,
                onPageChanged: (index) =>
                    _select(filtered[index], filtered, fromCard: true),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _MapEventCard(
                    event: filtered[index],
                    savedEventsRepository: widget.savedEventsRepository,
                    distanceKm: _userLocation == null
                        ? null
                        : const Distance().as(LengthUnit.Kilometer,
                            _userLocation!, _point(filtered[index])!),
                    selected: _selectedId == filtered[index].id ||
                        (_selectedId == null && index == 0),
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}

LatLng? _point(EventModel event) {
  final lat = double.tryParse(event.venue?.latitude ?? '');
  final lng = double.tryParse(event.venue?.longitude ?? '');
  if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
  return LatLng(lat, lng);
}

class _MapFilters extends StatelessWidget {
  const _MapFilters(
      {required this.cities,
      required this.selectedCity,
      required this.myLocation,
      required this.locating,
      required this.message,
      required this.eventCount,
      required this.onLocation,
      required this.onCity});
  final List<String> cities;
  final String? selectedCity;
  final bool myLocation;
  final bool locating;
  final String? message;
  final int eventCount;
  final VoidCallback onLocation;
  final ValueChanged<String?> onCity;

  @override
  Widget build(BuildContext context) => _Glass(
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterPill(
                      label: locating ? 'Locating…' : 'My Location',
                      icon: locating
                          ? Icons.sync_rounded
                          : Icons.near_me_outlined,
                      selected: myLocation,
                      onTap: onLocation),
                  _FilterPill(
                      label: 'All Zimbabwe',
                      selected: selectedCity == null && !myLocation,
                      onTap: () => onCity(null)),
                  for (final city in cities)
                    _FilterPill(
                        label: city,
                        selected: selectedCity == city,
                        onTap: () => onCity(city)),
                ],
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 3),
            child: Text(
                message ??
                    '$eventCount ${eventCount == 1 ? 'event' : 'events'} on the map',
                maxLines: 2,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11, height: 1.25)),
          ),
        ]),
      );
}

class _FilterPill extends StatelessWidget {
  const _FilterPill(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 7),
        child: Material(
          color: selected ? AppColors.purple : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 16,
                      color: selected ? Colors.white : AppColors.purple),
                  const SizedBox(width: 6),
                ],
                Text(label,
                    style: TextStyle(
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ),
      );
}

class _EventMarker extends StatelessWidget {
  const _EventMarker(
      {required this.selected, required this.label, required this.onTap});
  final bool selected;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: 'Select $label',
        child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white, width: selected ? 4 : 3),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x3D30105F),
                        blurRadius: 12,
                        offset: Offset(0, 6))
                  ]),
              child: Icon(Icons.event_rounded,
                  color: Colors.white, size: selected ? 27 : 21),
            )),
      );
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();
  @override
  Widget build(BuildContext context) => Container(
          decoration: BoxDecoration(
              color: const Color(0xFF2389FF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
            BoxShadow(color: Color(0x552389FF), blurRadius: 16)
          ]));
}

class _MapEventCard extends StatelessWidget {
  const _MapEventCard(
      {required this.event,
      required this.distanceKm,
      required this.selected,
      required this.savedEventsRepository});
  final EventModel event;
  final double? distanceKm;
  final bool selected;
  final SavedEventsRepository savedEventsRepository;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(event.start.local) ?? DateTime.now();
    return _Glass(
      padding: EdgeInsets.zero,
      selected: selected,
      child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/event/${event.id}', extra: event),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
                padding: const EdgeInsets.all(9),
                child: Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SizedBox(
                          width: 116,
                          height: double.infinity,
                          child: EventNetworkImage.forEvent(event))),
                  const SizedBox(width: 13),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text(DateFormat('EEE, d MMM · h:mm a').format(date),
                            style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
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
                        Row(children: [
                          Expanded(
                              child: Text(event.venue?.name ?? 'Venue TBA',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11))),
                          if (distanceKm != null)
                            Text(_distance(distanceKm!),
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                        ]),
                      ])),
                  SaveEventButton(
                    eventId: event.id,
                    repository: savedEventsRepository,
                  ),
                ])),
          )),
    );
  }

  String _distance(double value) => value < 1
      ? '${(value * 1000).round()} m'
      : '${value.toStringAsFixed(1)} km';
}

class _Glass extends StatelessWidget {
  const _Glass(
      {required this.child,
      this.padding = const EdgeInsets.all(14),
      this.selected = false});
  final Widget child;
  final EdgeInsets padding;
  final bool selected;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: padding,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: selected
                            ? AppColors.purple.withValues(alpha: .55)
                            : Colors.white.withValues(alpha: .8),
                        width: selected ? 1.5 : 1),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x1F0A0A14),
                          blurRadius: 22,
                          offset: Offset(0, 9))
                    ]),
                child: child)),
      );
}

class _MapLoading extends StatelessWidget {
  const _MapLoading();
  @override
  Widget build(BuildContext context) => const ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.map_outlined, size: 48, color: AppColors.purple),
        SizedBox(height: 12),
        Text('Preparing the event map…')
      ])));
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
                  onPressed: onRetry, child: const Text('Try again')),
            ],
          ])));
}
