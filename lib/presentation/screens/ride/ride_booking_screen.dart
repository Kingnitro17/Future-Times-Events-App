import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/geo/geo_point.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/ride.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/ride_repository.dart';
import '../../../services/transport/tap_and_go_provider.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({
    super.key,
    required this.authRepository,
    required this.rideRepository,
    required this.eventRepository,
    this.eventId,
  });

  final AuthRepository authRepository;
  final RideRepository rideRepository;
  final EventRepository eventRepository;
  final String? eventId;

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  late final TapAndGoProvider _provider;
  RideQuote? _quote;
  GeoPoint _pickup = const GeoPoint(lat: 0, lng: 0);
  GeoPoint _dropoff = const GeoPoint(lat: 0, lng: 0);
  EventModel? _event;
  bool _loading = true;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _provider = TapAndGoProvider();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.eventId != null) {
        _event = await widget.eventRepository.getEventById(widget.eventId!);
        final venue = _event?.venue;
        final lat = double.tryParse(venue?.latitude ?? '');
        final lng = double.tryParse(venue?.longitude ?? '');
        if (lat != null && lng != null) {
          _dropoff = GeoPoint(
            lat: lat,
            lng: lng,
            address: venue?.address?.localizedDisplay ?? venue?.name,
          );
          _dropoffController.text = _dropoff.address ?? '';
        }
      }
      await _useCurrentLocation();
      if (_dropoffController.text.isEmpty && _event?.venue != null) {
        _dropoffController.text = _event!.venue!.name;
      }
      await _refreshQuote();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not prepare the ride. Try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    _pickup = GeoPoint(
      lat: position.latitude,
      lng: position.longitude,
      address: 'Current location',
    );
    _pickupController.text = _pickup.address!;
  }

  Future<void> _refreshQuote() async {
    final quotes = await widget.rideRepository.getQuotes(
      pickup: _pickup,
      dropoff: _dropoff,
    );
    if (mounted) setState(() => _quote = quotes.isEmpty ? null : quotes.first);
  }

  Future<void> _book() async {
    final userId = widget.authRepository.user?.id;
    final quote = _quote;
    if (userId == null || quote == null) return;
    setState(() {
      _booking = true;
      _error = null;
    });
    try {
      final booking = await widget.rideRepository.createBooking(
        userId: userId,
        quote: quote,
        eventId: widget.eventId,
      );
      final launched = await launchUrl(
        _provider.buildDeepLink(pickup: _pickup, dropoff: _dropoff),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tap & Go could not be opened.')),
        );
      }
      if (!mounted) return;
      final completed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Did you complete the booking?'),
          content: const Text(
              'Return to Future Times after confirming your ride in Tap & Go.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (completed == true) {
        await widget.rideRepository.markAsBooked(rideId: booking.id);
      } else {
        await widget.rideRepository.markAsCancelled(booking.id);
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not create the ride. Try again.');
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Get a ride'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _quote == null
              ? _ErrorState(
                  message: _error!,
                  onRetry: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  })
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _field(
                        'Pickup', _pickupController, Icons.my_location_rounded,
                        pickup: true),
                    const SizedBox(height: 14),
                    _field('Drop-off', _dropoffController,
                        Icons.location_on_rounded),
                    const SizedBox(height: 22),
                    _quoteCard(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _booking || _quote == null ? null : _book,
                      child: _booking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Book with Tap & Go'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _booking ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon,
          {bool pickup = false}) =>
      TextField(
        controller: controller,
        onChanged: (value) {
          if (pickup) {
            _pickup = _pickup.copyWith(address: value);
          } else {
            _dropoff = _dropoff.copyWith(address: value);
          }
          setState(() => _quote = null);
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: pickup
              ? IconButton(
                  tooltip: 'Use current location',
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.gps_fixed_rounded),
                )
              : null,
        ),
      );

  Widget _quoteCard() {
    final quote = _quote;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: quote == null
            ? const Text('Enter pickup and drop-off details to get a quote.')
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.directions_car_rounded,
                      color: AppColors.purple),
                  const SizedBox(width: 10),
                  Text(quote.providerDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 14),
                Text(quote.fareEstimate == 0
                    ? 'Fare shown in Tap & Go app'
                    : '${quote.currency} ${quote.fareEstimate.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                Text(quote.etaMinutes == 0
                    ? 'ETA shown in Tap & Go app'
                    : '${quote.etaMinutes} min ETA'),
                if (quote.vehicleClass != null) Text(quote.vehicleClass!),
              ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}
