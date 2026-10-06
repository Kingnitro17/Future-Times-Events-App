import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../services/maps/location_service.dart';
import '../../services/maps/map_launcher_service.dart';
import '../../services/maps/routing_service.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';
import '../widgets/event_network_image.dart';
import '../widgets/map/event_map_pin.dart';
import '../widgets/save_event_button.dart';

class MapDiscoveryScreen extends StatefulWidget {
  const MapDiscoveryScreen({
    super.key,
    required this.savedEventsRepository,
  });

  final SavedEventsRepository savedEventsRepository;

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  static const _harare = LatLng(-17.8252, 31.0335);
  static const _categories = [
    'All',
    'Music',
    'Sports',
    'Food',
    'Nightlife',
    'Arts',
    'Business',
    'Other',
  ];

  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();
  final _searchController = TextEditingController();
  final _locationService = LocationService.instance;
  final _routingService = RoutingService();
  final _distance = const Distance();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _mapQueryDebounce;
  Timer? _rerouteTimer;
  LatLng? _userLocation;
  LatLng? _lastRouteOrigin;
  LatLngBounds? _lastQueriedBounds;
  List<EventModel>? _viewportEvents;
  String _query = '';
  String _category = 'All';
  String _priceFilter = 'Any';
  String _dateFilter = 'Any';
  Map<String, int> _startingPrices = const {};
  String? _selectedId;
  String? _locationMessage;
  String? _mapError;
  bool _locationPermissionNeeded = false;
  bool _openSettingsInstead = false;
  bool _locating = false;
  bool _mapReady = false;
  bool _directionsMode = false;
  bool _routing = false;
  bool _offline = false;
  int _permissionDenials = 0;
  int _queryGeneration = 0;
  int _sheetMode = 0;
  RouteResult? _route;
  EventModel? _destination;
  late final AnimationController _pulseController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    final bloc = context.read<EventBloc>();
    if (bloc.state is EventInitial) bloc.add(const FetchEvents());
    _checkLocationPermission();
    _rerouteTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _rerouteIfNeeded(),
    );
  }

  @override
  void dispose() {
    _mapQueryDebounce?.cancel();
    _rerouteTimer?.cancel();
    _positionSubscription?.cancel();
    _searchController.dispose();
    _pulseController.dispose();
    _sheetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await _locationService.checkPermission();
    if (!mounted) return;
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    setState(() {
      _locationPermissionNeeded = !granted;
      _openSettingsInstead = permission == LocationPermission.deniedForever;
    });
    if (granted) _startPositionStream();
  }

  void _startPositionStream() {
    if (_positionSubscription != null) return;
    _positionSubscription = _locationService.positionStream().listen(
      _onPosition,
      onError: (_) {
        if (mounted) setState(() => _locationPermissionNeeded = true);
      },
    );
  }

  void _onPosition(Position position) {
    if (!mounted) return;
    final location = LatLng(position.latitude, position.longitude);
    setState(() => _userLocation = location);
    final destination = _destination;
    final lastOrigin = _lastRouteOrigin;
    if (_directionsMode &&
        _route != null &&
        destination != null &&
        lastOrigin != null &&
        _distance.as(LengthUnit.Meter, lastOrigin, location) > 50) {
      _routeTo(destination, forceRefresh: true);
    }
  }

  Future<void> _requestLocation() async {
    if (_locating) return;
    HapticFeedback.selectionClick();
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    try {
      if (_openSettingsInstead) {
        await permissions.openAppSettings();
        return;
      }
      final allowed = await _locationService.requestPermission();
      if (!allowed) {
        _permissionDenials++;
        if (!mounted) return;
        setState(() {
          _locationPermissionNeeded = true;
          _openSettingsInstead = _permissionDenials >= 2;
          _locationMessage = _openSettingsInstead
              ? 'Location is disabled. Enable it in Settings to see nearby events.'
              : 'Location permission was not granted. You can still explore events.';
        });
        return;
      }
      _startPositionStream();
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      if (position == null) {
        setState(() {
          _locationMessage =
              'Could not get your location. Choose an event to keep exploring.';
        });
        return;
      }
      final location = LatLng(position.latitude, position.longitude);
      setState(() {
        _userLocation = location;
        _locationPermissionNeeded = false;
        _locationMessage =
            'Located · accuracy about ${position.accuracy.round()} m';
      });
      if (_mapReady) _mapController.move(location, 13);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Showing your location on the map.')),
      );
      if (_mapReady) _scheduleBoundsQuery(_mapController.camera);
    } on TimeoutException {
      if (mounted) {
        setState(() => _locationMessage =
            'Location took too long. Try again or explore without it.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationMessage =
            'We could not get your location. You can still explore events.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapReady() {
    _mapReady = true;
    _scheduleBoundsQuery(_mapController.camera);
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) _scheduleBoundsQuery(camera);
  }

  void _scheduleBoundsQuery(MapCamera camera) {
    _mapQueryDebounce?.cancel();
    _mapQueryDebounce = Timer(const Duration(milliseconds: 300), () {
      _queryEventsInBounds(camera.visibleBounds);
    });
  }

  Future<void> _queryEventsInBounds(LatLngBounds bounds) async {
    if (!mounted) return;
    if (_lastQueriedBounds case final previous?) {
      final sameBounds = (previous.north - bounds.north).abs() < .015 &&
          (previous.south - bounds.south).abs() < .015 &&
          (previous.east - bounds.east).abs() < .015 &&
          (previous.west - bounds.west).abs() < .015;
      if (sameBounds) return;
    }
    _lastQueriedBounds = bounds;
    final generation = ++_queryGeneration;
    try {
      final events = await context.read<EventBloc>().getEventsWithinBounds(
            northEastLat: bounds.north,
            northEastLng: bounds.east,
            southWestLat: bounds.south,
            southWestLng: bounds.west,
            limit: 200,
          );
      if (!mounted || generation != _queryGeneration) return;
      setState(() {
        _viewportEvents = events;
        _offline = false;
        _mapError = null;
      });
      if (_priceFilter == 'Under \$10') {
        await _loadStartingPrices(events);
      }
    } catch (_) {
      if (!mounted || generation != _queryGeneration) return;
      setState(() {
        _offline = true;
        _mapError = 'Could not refresh events for this area.';
      });
    }
  }

  List<EventModel> _visibleEvents(List<EventModel> allEvents) {
    final source = _viewportEvents ?? allEvents;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysUntilSaturday = (DateTime.saturday - today.weekday + 7) % 7;
    final weekendStart = today.add(
      Duration(days: today.weekday == DateTime.sunday ? -1 : daysUntilSaturday),
    );
    final weekendEnd = weekendStart.add(const Duration(days: 2));
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final query = _query.trim().toLowerCase();
    return source.where((event) {
      if (mapPointForEvent(event) == null || event.status != 'published') {
        return false;
      }
      if (query.isNotEmpty &&
          !event.name.text.toLowerCase().contains(query) &&
          !(event.venue?.name.toLowerCase().contains(query) ?? false)) {
        return false;
      }
      if (_category != 'All' &&
          _categoryForEvent(event) != _category &&
          !event.categoryLabel
              .toString()
              .toLowerCase()
              .contains(_category.toLowerCase())) {
        return false;
      }
      if (_priceFilter == 'Free' && !event.isFree) return false;
      if (_priceFilter == 'Under \$10' &&
          !(_startingPrices[event.id] != null &&
              _startingPrices[event.id]! < 1000)) {
        return false;
      }
      final date = event.startsAt;
      if (_dateFilter == 'Today' &&
          (date.isBefore(today) ||
              !date.isBefore(today.add(const Duration(days: 1))))) {
        return false;
      }
      if (_dateFilter == 'This weekend' &&
          (date.isBefore(today) ||
              date.isBefore(weekendStart) ||
              !date.isBefore(weekendEnd))) {
        return false;
      }
      if (_dateFilter == 'This month' &&
          (date.isBefore(today) || !date.isBefore(monthEnd))) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        if (_userLocation != null) {
          return _distance
              .as(LengthUnit.Meter, _userLocation!, mapPointForEvent(a)!)
              .compareTo(_distance.as(
                LengthUnit.Meter,
                _userLocation!,
                mapPointForEvent(b)!,
              ));
        }
        return a.startsAt.compareTo(b.startsAt);
      });
  }

  Future<void> _loadStartingPrices(List<EventModel> events) async {
    try {
      final prices = await context.read<EventBloc>().getStartingPrices(
            events.map((event) => event.id),
          );
      if (mounted) setState(() => _startingPrices = prices);
    } catch (_) {
      if (mounted) {
        setState(() {
          _mapError = 'Could not load event prices. Try again.';
          _offline = false;
        });
      }
    }
  }

  Future<void> _toggleDirections() async {
    HapticFeedback.selectionClick();
    final enable = !_directionsMode;
    setState(() {
      _directionsMode = enable;
      if (!enable) _clearRoute();
    });
    if (enable && _userLocation == null) await _requestLocation();
  }

  Future<void> _routeTo(EventModel event, {bool forceRefresh = false}) async {
    final destination = mapPointForEvent(event);
    if (destination == null) {
      _showMessage('This event does not have valid venue coordinates.');
      return;
    }
    if (_userLocation == null) {
      await _requestLocation();
      if (_userLocation == null) return;
    }
    final origin = _userLocation!;
    setState(() {
      _routing = true;
      _mapError = null;
      _destination = event;
    });
    final route = forceRefresh
        ? await _routingService.refreshRoute(
            fromLat: origin.latitude,
            fromLng: origin.longitude,
            toLat: destination.latitude,
            toLng: destination.longitude,
          )
        : await _routingService.getRoute(
            fromLat: origin.latitude,
            fromLng: origin.longitude,
            toLat: destination.latitude,
            toLng: destination.longitude,
          );
    if (!mounted) return;
    setState(() {
      _routing = false;
      _route = route;
      _lastRouteOrigin = origin;
      if (route == null) _mapError = 'Could not calculate a route. Try again.';
    });
    if (route != null && route.polyline.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.polyline),
          padding: const EdgeInsets.fromLTRB(56, 180, 56, 250),
        ),
      );
    }
  }

  Future<void> _rerouteIfNeeded() async {
    final destination = _destination;
    final origin = _userLocation;
    final previous = _lastRouteOrigin;
    if (!_directionsMode ||
        _route == null ||
        destination == null ||
        origin == null ||
        previous == null ||
        _routing ||
        _distance.as(LengthUnit.Meter, previous, origin) <= 50) {
      return;
    }
    await _routeTo(destination, forceRefresh: true);
  }

  void _clearRoute() {
    _routing = false;
    _route = null;
    _destination = null;
    _lastRouteOrigin = null;
    _mapError = null;
  }

  void _resetFilters() {
    setState(() {
      _category = 'All';
      _priceFilter = 'Any';
      _dateFilter = 'Any';
      _query = '';
      _searchController.clear();
      _mapError = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: BlocBuilder<EventBloc, EventState>(
        builder: (context, state) {
          final sourceEvents =
              state is EventLoaded ? state.events : <EventModel>[];
          final events = _visibleEvents(sourceEvents);
          final markers = _markersFor(events);
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _harare,
                  initialZoom: 11,
                  minZoom: 3,
                  maxZoom: 19,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onMapReady: _onMapReady,
                  onPositionChanged: _onMapPositionChanged,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.futuretimes.events',
                    maxZoom: 19,
                    errorTileCallback: (_, __, ___) {
                      if (mounted && !_offline) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _offline = true);
                        });
                      }
                    },
                  ),
                  if (_route != null) PolylineLayer(polylines: _routeLines),
                  MarkerLayer(markers: markers),
                  if (_userLocation != null)
                    MarkerLayer(markers: [_userMarker(_userLocation!)]),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => _openAttribution(),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: topInset + 10,
                left: 14,
                right: 14,
                child: _topControls(),
              ),
              if (_directionsMode && _route == null && !_routing)
                Positioned(
                  top: topInset + 138,
                  left: 20,
                  right: 20,
                  child: const _FloatingBanner(
                    icon: Icons.near_me_rounded,
                    message: 'Tap an event to route to it',
                  ),
                ),
              if (_route != null && _destination != null)
                Positioned(
                  top: topInset + 136,
                  left: 18,
                  right: 18,
                  child: _RouteSummaryCard(
                    destination: _destination!,
                    route: _route!,
                    onStart: _startExternalNavigation,
                    onSteps: _showRouteSteps,
                    onExit: () => setState(_clearRoute),
                  ),
                ),
              if (_routing)
                Positioned(
                  top: topInset + 138,
                  left: 20,
                  right: 20,
                  child: const _FloatingBanner(
                    icon: Icons.sync_rounded,
                    message: 'Calculating route…',
                    busy: true,
                  ),
                ),
              if (_offline)
                Positioned(
                  top: topInset + 132,
                  left: 18,
                  right: 18,
                  child: _FloatingBanner(
                    icon: Icons.wifi_off_rounded,
                    message: 'Connection unavailable. Map tiles may not load.',
                    action: TextButton(
                      onPressed: () {
                        setState(() => _offline = false);
                        _lastQueriedBounds = null;
                        if (_mapReady) {
                          _queryEventsInBounds(
                            _mapController.camera.visibleBounds,
                          );
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ),
                ),
              if (_mapError != null && !_offline)
                Positioned(
                  top: topInset + 136,
                  left: 18,
                  right: 18,
                  child: _FloatingBanner(
                    icon: Icons.cloud_off_rounded,
                    message: _mapError!,
                    action: TextButton(
                      onPressed: () {
                        _lastQueriedBounds = null;
                        if (_mapReady) {
                          _queryEventsInBounds(
                              _mapController.camera.visibleBounds);
                        }
                        final destination = _destination;
                        if (destination != null) _routeTo(destination);
                      },
                      child: const Text('Retry'),
                    ),
                  ),
                ),
              _eventSheet(events),
              Positioned(
                right: 16,
                bottom: _sheetMode == 2 ? 350 : (_sheetMode == 1 ? 250 : 170),
                child: _mapActions(),
              ),
              if (_locationPermissionNeeded)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _permissionBanner(),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Polyline> get _routeLines {
    final route = _route;
    if (route == null) return const [];
    return [
      Polyline(points: route.polyline, color: Colors.white, strokeWidth: 8),
      Polyline(
        points: route.polyline,
        color: AppColors.purple,
        strokeWidth: 5,
      ),
    ];
  }

  Widget _topControls() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: _glassDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.purple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search events or venues',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Price and date filters',
                      onPressed: _showFilters,
                      icon: Badge(
                        isLabelVisible:
                            _priceFilter != 'Any' || _dateFilter != 'Any',
                        child: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final category in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                      selectedColor: AppColors.purple,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _category == category
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
        ],
      );

  Future<void> _showFilters() async {
    var selectedPrice = _priceFilter;
    var selectedDate = _dateFilter;
    final result = await showModalBottomSheet<({String price, String date})>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, modalSetState) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter events',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text('Price'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in ['Any', 'Free', 'Under \$10'])
                      ChoiceChip(
                        label: Text(option),
                        selected: selectedPrice == option,
                        onSelected: (_) =>
                            modalSetState(() => selectedPrice = option),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Date'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in [
                      'Any',
                      'Today',
                      'This weekend',
                      'This month',
                    ])
                      ChoiceChip(
                        label: Text(option),
                        selected: selectedDate == option,
                        onSelected: (_) =>
                            modalSetState(() => selectedDate = option),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (price: selectedPrice, date: selectedDate),
                    ),
                    child: const Text('Show events'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _priceFilter = result.price;
        _dateFilter = result.date;
      });
      if (result.price == 'Under \$10') {
        final events = _viewportEvents ??
            ((context.read<EventBloc>().state is EventLoaded)
                ? (context.read<EventBloc>().state as EventLoaded).events
                : <EventModel>[]);
        await _loadStartingPrices(events);
      }
    }
  }

  List<Marker> _markersFor(List<EventModel> events) {
    if (!_mapReady) {
      return [
        for (final event in events)
          if (mapPointForEvent(event) case final point?)
            Marker(
              point: point,
              width: 194,
              height: 60,
              alignment: Alignment.bottomCenter,
              child: _EventMapMarker(
                event: event,
                selected: _selectedId == event.id,
                onTap: () => _onEventSelected(event, events),
              ),
            ),
      ];
    }
    final camera = _mapController.camera;
    final visible = events.where((event) {
      final point = mapPointForEvent(event);
      return point != null && camera.visibleBounds.contains(point);
    }).toList(growable: false);
    if (camera.zoom >= 12 || visible.length <= 20) {
      return [
        for (final event in visible)
          if (mapPointForEvent(event) case final point?)
            Marker(
              point: point,
              width: 194,
              height: 60,
              alignment: Alignment.bottomCenter,
              child: _EventMapMarker(
                event: event,
                selected: _selectedId == event.id,
                onTap: () => _onEventSelected(event, events),
              ),
            ),
      ];
    }

    final bounds = camera.visibleBounds;
    final latSpan = math.max(bounds.north - bounds.south, .0001);
    final lngSpan = math.max(bounds.east - bounds.west, .0001);
    final cells = <String, List<EventModel>>{};
    for (final event in visible) {
      final point = mapPointForEvent(event);
      if (point == null || !bounds.contains(point)) continue;
      final row = (((bounds.north - point.latitude) / latSpan) * 10)
          .floor()
          .clamp(0, 9);
      final column = (((point.longitude - bounds.west) / lngSpan) * 10)
          .floor()
          .clamp(0, 9);
      cells.putIfAbsent('$row:$column', () => []).add(event);
    }
    return [
      for (final items in cells.values)
        if (items.length == 1)
          Marker(
            point: mapPointForEvent(items.single)!,
            width: 194,
            height: 60,
            alignment: Alignment.bottomCenter,
            child: _EventMapMarker(
              event: items.single,
              selected: _selectedId == items.single.id,
              onTap: () => _onEventSelected(items.single, events),
            ),
          )
        else
          Marker(
            point: _clusterCenter(items),
            width: _clusterSize(items.length),
            height: _clusterSize(items.length),
            child: _ClusterMarker(
              count: items.length,
              onTap: () => _zoomToCluster(items),
            ),
          ),
    ];
  }

  LatLng _clusterCenter(List<EventModel> events) {
    final points = events.map(mapPointForEvent).whereType<LatLng>().toList();
    return LatLng(
      points.map((point) => point.latitude).reduce((a, b) => a + b) /
          points.length,
      points.map((point) => point.longitude).reduce((a, b) => a + b) /
          points.length,
    );
  }

  double _clusterSize(int count) => count >= 100 ? 60 : (count >= 50 ? 50 : 40);

  void _zoomToCluster(List<EventModel> events) {
    final points = events.map(mapPointForEvent).whereType<LatLng>().toList();
    if (points.length < 2) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(70),
        maxZoom: 15,
      ),
    );
  }

  Marker _userMarker(LatLng point) => Marker(
        point: point,
        width: 38,
        height: 38,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Opacity(
            opacity: .6 + (_pulseController.value * .4),
            child: child,
          ),
          child: const _UserLocationMarker(),
        ),
      );

  Widget _mapActions() => Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'map-my-location',
            tooltip: 'My location',
            onPressed: _requestLocation,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.purple,
            child: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'map-directions-mode',
            tooltip: 'Directions mode',
            onPressed: _toggleDirections,
            backgroundColor: _directionsMode ? AppColors.purple : Colors.white,
            foregroundColor: _directionsMode ? Colors.white : AppColors.purple,
            child: const Icon(Icons.navigation_rounded),
          ),
          if (_directionsMode || _route != null) ...[
            const SizedBox(height: 10),
            FloatingActionButton.small(
              heroTag: 'map-reset-directions',
              tooltip: 'Exit directions',
              onPressed: () => setState(() {
                _directionsMode = false;
                _clearRoute();
              }),
              backgroundColor: Colors.white,
              foregroundColor: AppColors.purple,
              child: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      );

  Widget _permissionBanner() => _FloatingBanner(
        icon: Icons.location_on_outlined,
        message: _locationMessage ?? 'Enable location for nearby events.',
        action: TextButton(
          onPressed: _requestLocation,
          child: Text(_openSettingsInstead ? 'Settings' : 'Enable'),
        ),
      );

  Widget _eventSheet(List<EventModel> events) => DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: .15,
        minChildSize: .12,
        maxChildSize: .82,
        snap: true,
        snapSizes: const [.15, .48, .82],
        builder: (context, scrollController) =>
            NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            final mode = notification.extent > .68
                ? 2
                : (notification.extent > .28 ? 1 : 0);
            if (mode != _sheetMode && mounted) {
              setState(() => _sheetMode = mode);
            }
            return false;
          },
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x220A0A14),
                  blurRadius: 22,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${events.length} ${events.length == 1 ? 'event' : 'events'} nearby',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (_mapError != null && !_offline)
                              IconButton(
                                tooltip: 'Retry loading events',
                                onPressed: () {
                                  _lastQueriedBounds = null;
                                  if (_mapReady) {
                                    _queryEventsInBounds(
                                      _mapController.camera.visibleBounds,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                            if (_priceFilter != 'Any' || _dateFilter != 'Any')
                              TextButton(
                                onPressed: _resetFilters,
                                child: const Text('Clear filters'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (events.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyMapResults(onReset: _resetFilters),
                  )
                else if (_sheetMode == 1)
                  SliverToBoxAdapter(child: _eventCarousel(events))
                else if (_sheetMode == 2)
                  SliverList.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        index == 0 ? 8 : 0,
                        14,
                        index == events.length - 1 ? 20 : 0,
                      ),
                      child: _EventListCard(
                        event: events[index],
                        savedEventsRepository: widget.savedEventsRepository,
                        distanceKm: _distanceFromUser(events[index]),
                        onOpen: () => _openEvent(events[index]),
                        onDirections: () => _routeTo(events[index]),
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 6)),
              ],
            ),
          ),
        ),
      );

  Widget _eventCarousel(List<EventModel> events) {
    final ordered = [...events];
    final selectedIndex =
        ordered.indexWhere((event) => event.id == _selectedId);
    if (selectedIndex > 0) {
      final selected = ordered.removeAt(selectedIndex);
      ordered.insert(0, selected);
    }
    return SizedBox(
      height: 258,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
        scrollDirection: Axis.horizontal,
        itemCount: ordered.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final event = ordered[index];
          return SizedBox(
            width: 270,
            child: _EventCarouselCard(
              event: event,
              savedEventsRepository: widget.savedEventsRepository,
              distanceKm: _distanceFromUser(event),
              onOpen: () => _openEvent(event),
              onDirections: () => _routeTo(event),
            ),
          );
        },
      ),
    );
  }

  double? _distanceFromUser(EventModel event) {
    final point = mapPointForEvent(event);
    final origin = _userLocation;
    if (point == null || origin == null) return null;
    return _distance.as(LengthUnit.Kilometer, origin, point);
  }

  void _onEventSelected(EventModel event, List<EventModel> events) {
    HapticFeedback.selectionClick();
    if (_directionsMode) {
      _routeTo(event);
      return;
    }
    final point = mapPointForEvent(event);
    if (point == null) return;
    setState(() {
      _selectedId = event.id;
      _sheetMode = 1;
    });
    _sheetController.animateTo(
      .48,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    if (_mapReady) {
      _mapController.move(point, math.max(_mapController.camera.zoom, 13));
    }
  }

  void _openEvent(EventModel event) =>
      context.push('/event/${event.id}', extra: event);

  Future<void> _startExternalNavigation() async {
    final destination = _destination;
    final point = destination == null ? null : mapPointForEvent(destination);
    if (destination == null || point == null) return;
    await MapLauncherService.navigateTo(
      context: context,
      latitude: point.latitude,
      longitude: point.longitude,
      destinationTitle: destination.name.text,
      originLatitude: _userLocation?.latitude,
      originLongitude: _userLocation?.longitude,
      originTitle: 'My location',
      mode: TravelMode.driving,
    );
  }

  Future<void> _showRouteSteps() async {
    final route = _route;
    if (route == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .68,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  _destination?.name.text ?? 'Route steps',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${route.distanceText} · ${route.durationText}'),
                trailing: IconButton(
                  tooltip: 'Start navigation',
                  onPressed: () {
                    Navigator.pop(context);
                    _startExternalNavigation();
                  },
                  icon: const Icon(Icons.navigation_rounded),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: route.steps.length,
                  itemBuilder: (context, index) {
                    final step = route.steps[index];
                    return ListTile(
                      selected: index == 0,
                      leading: CircleAvatar(
                        backgroundColor: index == 0
                            ? AppColors.purple
                            : AppColors.surfaceMuted,
                        foregroundColor:
                            index == 0 ? Colors.white : AppColors.purple,
                        child: Icon(_maneuverIcon(step.maneuverType)),
                      ),
                      title: Text(step.instruction),
                      trailing: Text(_formatDistance(step.distanceMeters)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _maneuverIcon(String type) => switch (type) {
        'turn' => Icons.turn_right_rounded,
        'roundabout' || 'rotary' => Icons.roundabout_left_rounded,
        'arrive' => Icons.flag_rounded,
        'depart' => Icons.trip_origin_rounded,
        'merge' => Icons.merge_rounded,
        _ => Icons.navigation_rounded,
      };

  Future<void> _openAttribution() async {
    await launchUrl(
      Uri.https('www.openstreetmap.org', '/copyright'),
      mode: LaunchMode.externalApplication,
    );
  }
}

LatLng? mapPointForEvent(EventModel event) {
  final lat = double.tryParse(event.venue?.latitude ?? '');
  final lng = double.tryParse(event.venue?.longitude ?? '');
  if (lat == null ||
      lng == null ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180 ||
      (lat == 0 && lng == 0)) {
    return null;
  }
  return LatLng(lat, lng);
}

List<EventModel> filterEventsForMap(
  Iterable<EventModel> events, {
  String? city,
  LatLng? userLocation,
}) {
  final normalizedCity = city?.trim().toLowerCase();
  final filtered = events.where((event) {
    if (mapPointForEvent(event) == null) return false;
    if (normalizedCity == null || normalizedCity.isEmpty) return true;
    return event.venue?.address?.city?.trim().toLowerCase() == normalizedCity;
  }).toList();
  if (userLocation != null) {
    const distance = Distance();
    filtered.sort((first, second) {
      final firstPoint = mapPointForEvent(first)!;
      final secondPoint = mapPointForEvent(second)!;
      return distance
          .as(LengthUnit.Meter, userLocation, firstPoint)
          .compareTo(distance.as(LengthUnit.Meter, userLocation, secondPoint));
    });
  }
  return filtered;
}

String _categoryForEvent(EventModel event) {
  final category =
      '${event.categoryLabel ?? ''} ${event.categoryId ?? ''}'.toLowerCase();
  if (category.contains('music') || category.contains('concert')) {
    return 'Music';
  }
  if (category.contains('sport') || category.contains('fitness')) {
    return 'Sports';
  }
  if (category.contains('food') || category.contains('drink')) {
    return 'Food';
  }
  if (category.contains('night') || category.contains('club')) {
    return 'Nightlife';
  }
  if (category.contains('art') || category.contains('culture')) {
    return 'Arts';
  }
  if (category.contains('business') || category.contains('network')) {
    return 'Business';
  }
  return 'Other';
}

class _EventMapMarker extends StatelessWidget {
  const _EventMapMarker({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final EventModel event;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EventMapPin(
      eventImageUrl: event.logo?.original?.url ?? event.logo?.url,
      eventName: event.name.text.trim(),
      category: event.categoryLabel ?? event.categoryId,
      isSelected: selected,
      onTap: onTap,
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.purple,
        shape: const CircleBorder(),
        elevation: 8,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2389FF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x552389FF), blurRadius: 15, spreadRadius: 2),
          ],
        ),
        // Device heading rotation can be added when heading data is available.
      );
}

class _EventCarouselCard extends StatelessWidget {
  const _EventCarouselCard({
    required this.event,
    required this.savedEventsRepository,
    required this.distanceKm,
    required this.onOpen,
    required this.onDirections,
  });

  final EventModel event;
  final SavedEventsRepository savedEventsRepository;
  final double? distanceKm;
  final VoidCallback onOpen;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 152,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EventNetworkImage.forEvent(event),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: SaveEventButton(
                        eventId: event.id,
                        repository: savedEventsRepository,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 7, 7, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              event.name.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              [
                                event.venue?.name ?? 'Venue TBA',
                                if (distanceKm != null)
                                  _formatDistance(distanceKm! * 1000),
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Get directions',
                        onPressed: onDirections,
                        icon: const Icon(
                          Icons.directions_rounded,
                          color: AppColors.purple,
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

class _EventListCard extends StatelessWidget {
  const _EventListCard({
    required this.event,
    required this.savedEventsRepository,
    required this.distanceKm,
    required this.onOpen,
    required this.onDirections,
  });

  final EventModel event;
  final SavedEventsRepository savedEventsRepository;
  final double? distanceKm;
  final VoidCallback onOpen;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final date = event.startsAt;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          height: 116,
          child: Row(
            children: [
              SizedBox(
                width: 124,
                height: double.infinity,
                child: EventNetworkImage.forEvent(event),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE, d MMM · h:mm a').format(date),
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.name.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        [
                          event.venue?.name ?? 'Venue TBA',
                          if (distanceKm != null)
                            '${_formatDistance(distanceKm! * 1000)} away',
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SaveEventButton(
                    eventId: event.id,
                    repository: savedEventsRepository,
                  ),
                  IconButton(
                    tooltip: 'Get directions',
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.destination,
    required this.route,
    required this.onStart,
    required this.onSteps,
    required this.onExit,
  });

  final EventModel destination;
  final RouteResult route;
  final VoidCallback onStart;
  final VoidCallback onSteps;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final arrival = DateTime.now().add(
      Duration(seconds: route.durationSeconds.round()),
    );
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.navigation_rounded, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination.name.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Exit directions',
                onPressed: onExit,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Text(
            '${route.distanceText} · ${route.durationText} · Arrive ~${DateFormat('h:mm a').format(arrival)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onSteps,
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Steps'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMapResults extends StatelessWidget {
  const _EmptyMapResults({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 38, color: AppColors.purple),
              const SizedBox(height: 8),
              const Text(
                'No events match your filters',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextButton(
                  onPressed: onReset, child: const Text('Reset filters')),
            ],
          ),
        ),
      );
}

class _FloatingBanner extends StatelessWidget {
  const _FloatingBanner({
    required this.icon,
    required this.message,
    this.action,
    this.busy = false,
  });

  final IconData icon;
  final String message;
  final Widget? action;
  final bool busy;

  @override
  Widget build(BuildContext context) => _GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        child: Row(
          children: [
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, color: AppColors.purple, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: _glassDecoration(),
            child: child,
          ),
        ),
      );
}

BoxDecoration _glassDecoration() => BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .75)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x220A0A14),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    );

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
