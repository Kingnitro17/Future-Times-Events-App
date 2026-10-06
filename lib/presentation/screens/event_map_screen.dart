import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../services/maps/map_launcher_service.dart';
import '../../logic/blocs/social/social_bloc.dart';
import '../../logic/blocs/social/social_event.dart';
import '../../logic/blocs/social/social_state.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/event_network_image.dart';
import '../widgets/map/event_map_pin.dart';

class EventMapScreen extends StatefulWidget {
  final EventModel event;

  const EventMapScreen({super.key, required this.event});

  @override
  State<EventMapScreen> createState() => _EventMapScreenState();
}

class _EventMapScreenState extends State<EventMapScreen> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    context.read<SocialBloc>().add(WatchAttendees(eventId: widget.event.id));
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = _eventCoordinates;
    final center = coordinates ?? const LatLng(-17.8252, 31.0335);

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(center),
          _buildBackButton(),
          _buildBottomCard(coordinates),
        ],
      ),
    );
  }

  Widget _buildMap(LatLng center) {
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        final attendees = state is SocialLoaded ? state.attendees : [];

        final markers = <Marker>[
          Marker(
            point: center,
            width: 186,
            height: 60,
            alignment: Alignment.bottomCenter,
            child: EventMapPin(
              eventImageUrl:
                  widget.event.logo?.original?.url ?? widget.event.logo?.url,
              eventName: widget.event.name.text.trim(),
              category: widget.event.categoryLabel ?? widget.event.categoryId,
            ),
          ),
        ];

        // Attendee orbital markers
        const distance = Distance();
        final maxAttendees = attendees.take(12).toList();
        for (int i = 0; i < maxAttendees.length; i++) {
          final angle = (360 / maxAttendees.length) * i;
          // Offset each avatar by ~150 meters away from the center
          final point = distance.offset(center, 150, angle);

          markers.add(
            Marker(
              point: point,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.electricIndigo, width: 2),
                  image: (maxAttendees[i].avatarUrl != null &&
                          maxAttendees[i].avatarUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(maxAttendees[i].avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: AppTheme.charcoalSurface,
                  boxShadow: AppTheme.indigoGlow,
                ),
                child: maxAttendees[i].avatarUrl == null
                    ? const Icon(Icons.person,
                        color: AppTheme.subtleGrey, size: 20)
                    : null,
              ).animate().scale(
                  duration: 500.ms,
                  delay: (i * 100).ms,
                  curve: Curves.easeOutBack),
            ),
          );
        }

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 16.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.futuretimes.events',
            ),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
      ).animate().fade().slideX(begin: -0.5, end: 0, curve: Curves.easeOut),
    );
  }

  Widget _buildBottomCard(LatLng? coordinates) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppTheme.radiusSmall,
              child: SizedBox(
                width: 64,
                height: 64,
                child: EventNetworkImage.forEvent(widget.event),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.event.name.text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppTheme.electricIndigo, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.event.venue?.name ?? 'TBA',
                          style: const TextStyle(
                              color: AppTheme.subtleGrey, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (coordinates != null) ...[
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _openDirections(
                  coordinates.latitude,
                  coordinates.longitude,
                ),
                icon: const Icon(Icons.directions_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.electricIndigo,
                ),
                tooltip: 'Get Directions',
              ),
            ],
          ],
        ),
      ).animate().slideY(
          begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutQuart),
    );
  }

  LatLng? get _eventCoordinates {
    final latitude = double.tryParse(widget.event.venue?.latitude ?? '');
    final longitude = double.tryParse(widget.event.venue?.longitude ?? '');
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude == 0 && longitude == 0)) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  Future<void> _openDirections(double lat, double lng) async {
    await MapLauncherService.navigateTo(
      context: context,
      latitude: lat,
      longitude: lng,
      destinationTitle: widget.event.name.text,
    );
  }
}
