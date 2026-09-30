import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/event_discovery.dart';
import '../../data/models/event_model.dart';
import '../../data/models/zimbabwe_location.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/discovery_preferences_repository.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../data/repositories/zimbabwe_locations_repository.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';
import '../../core/utils/responsive_utils.dart';
import '../../data/repositories/social_repository.dart';
import '../widgets/event_network_image.dart';
import '../widgets/save_heart_button.dart';
import '../widgets/share_event_button.dart';
import '../widgets/event_social_row.dart';
import '../widgets/hero_banner.dart';
import '../widgets/ft_services_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.authRepository,
    required this.savedEventsRepository,
    required this.preferencesRepository,
    required this.socialRepository,
  });

  final AuthRepository authRepository;
  final SavedEventsRepository savedEventsRepository;
  final DiscoveryPreferencesRepository preferencesRepository;
  final SocialRepository socialRepository;

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
                        preferencesRepository: widget.preferencesRepository,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: HeroBanner(
                        imageAsset: 'assets/images/hero.png',
                        headline: 'Discover What’s Happening',
                        subheadline:
                            'Find events, buy tickets, and never miss out.',
                        buttonLabel: 'Explore Events',
                        onButtonPressed: () => context.push('/explore'),
                        greeting: _firstName(widget.authRepository),
                        semanticLabel:
                            'Explore events banner. Opens event search.',
                      ),
                    ),
                    if (state is EventLoading || state is EventInitial)
                      const SliverToBoxAdapter(child: _HomeSkeleton())
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
                            authRepository: widget.authRepository,
                            socialRepository: widget.socialRepository,
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
                              authRepository: widget.authRepository,
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
                              authRepository: widget.authRepository,
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
                            authRepository: widget.authRepository,
                            socialRepository: widget.socialRepository,
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
                              authRepository: widget.authRepository,
                            ),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 8),
                      ),
                    ],
                    SliverToBoxAdapter(child: FtServicesSection()),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

String _formatLocationSubtitle(String city) {
  final trimmed = city.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'all zimbabwe') {
    return 'All Zimbabwe';
  }

  if (trimmed.toLowerCase().endsWith(', zimbabwe')) {
    return trimmed;
  }
  return '$trimmed, Zimbabwe';
}

String _firstName(AuthRepository authRepository) {
  final profileName = authRepository.profile?['display_name']?.toString();
  final metadata = authRepository.user?.userMetadata;
  final name = (profileName != null && profileName.trim().isNotEmpty)
      ? profileName
      : metadata?['display_name']?.toString() ??
          metadata?['full_name']?.toString() ??
          authRepository.user?.email?.split('@').first;
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? 'Welcome' : trimmed.split(RegExp(r'\s+')).first;
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: authRepository,
        builder: (context, _) => _buildAvatar(),
      );

  Widget _buildAvatar() {
    final profile = authRepository.profile;
    final metadata = authRepository.user?.userMetadata;
    final displayName = _firstName(authRepository);
    final url = profile?['avatar_url']?.toString() ??
        metadata?['avatar_url']?.toString();
    final initials = displayName == 'Welcome'
        ? 'W'
        : displayName.substring(0, 1).toUpperCase();
    Widget fallback() => CircleAvatar(
          backgroundColor: AppColors.purple,
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        );
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.purple, width: 2),
        ),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback())
            : fallback(),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.authRepository,
    required this.preferredCity,
    required this.preferencesRepository,
  });

  final AuthRepository authRepository;
  final String preferredCity;
  final DiscoveryPreferencesRepository preferencesRepository;

  void _openLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerSheet(
        preferencesRepository: preferencesRepository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationText = _formatLocationSubtitle(preferredCity);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Image.asset(
                  'assets/images/appicon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openLocationPicker(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Discover what's\nhappening near",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppColors.purple,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  locationText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: AppColors.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.calendar_month_outlined,
                tooltip: 'Calendar',
                onTap: () => context.push('/calendar'),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.person_rounded,
                tooltip: 'Profile',
                onTap: () => context.push('/profile'),
                customIcon: _ProfileAvatar(authRepository: authRepository),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({required this.preferencesRepository});

  final DiscoveryPreferencesRepository preferencesRepository;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _searchController = TextEditingController();
  final _locationsRepository = const ZimbabweLocationsRepository();
  String _searchQuery = '';
  bool _isLocating = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectCity(String city, {double? lat, double? lng}) async {
    HapticFeedback.selectionClick();
    await widget.preferencesRepository.save(
      city: city,
      interests: widget.preferencesRepository.interests,
      latitude: lat ?? widget.preferencesRepository.latitude,
      longitude: lng ?? widget.preferencesRepository.longitude,
    );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location changed to $city'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _locateUser() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLocating = true;
      _statusMessage = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLocating = false;
            _statusMessage = 'Location services are disabled on your device.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLocating = false;
              _statusMessage = 'Location permission denied.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLocating = false;
            _statusMessage = 'Location permission permanently denied.';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final nearest = _locationsRepository.findNearestLocation(
        position.latitude,
        position.longitude,
      );

      await _selectCity(
        nearest.displayName,
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _statusMessage = 'Could not determine location.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCity = widget.preferencesRepository.city.isEmpty
        ? 'Harare'
        : widget.preferencesRepository.city;

    final List<ZimbabweLocation> displayedLocations = _searchQuery
            .trim()
            .isNotEmpty
        ? _locationsRepository.searchLocations(_searchQuery)
        : _locationsRepository.getSortedLocations(preferredCity: currentCity);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Change Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Explore events near your selected city in Zimbabwe.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search city or town...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All Zimbabwe'),
                      avatar: const Icon(Icons.public_rounded, size: 16),
                      selected: currentCity == 'All Zimbabwe',
                      onSelected: (_) => _selectCity('All Zimbabwe'),
                      selectedColor: AppColors.purple.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: currentCity == 'All Zimbabwe'
                            ? AppColors.purple
                            : AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    ActionChip(
                      label:
                          Text(_isLocating ? 'Locating...' : 'Use my location'),
                      avatar: _isLocating
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 16),
                      onPressed: _isLocating ? null : _locateUser,
                      labelStyle: const TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.contains('Resolved')
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: displayedLocations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final loc = displayedLocations[index];
                final isSelected =
                    currentCity.toLowerCase() == loc.displayName.toLowerCase();
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? AppColors.purple.withValues(alpha: 0.08)
                      : null,
                  leading: Icon(
                    Icons.location_city_rounded,
                    color: isSelected ? AppColors.purple : AppColors.textMuted,
                    size: 20,
                  ),
                  title: Text(
                    loc.displayName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.purple : AppColors.text,
                    ),
                  ),
                  subtitle: Text(
                    loc.province,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.purple,
                          size: 20,
                        )
                      : null,
                  onTap: () => _selectCity(loc.displayName,
                      lat: loc.latitude, lng: loc.longitude),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.customIcon,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Widget? customIcon;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: customIcon ?? Icon(icon),
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
    required this.authRepository,
    required this.socialRepository,
  });

  final List<EventModel> events;
  final SavedEventsRepository savedEventsRepository;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = ResponsiveUtils.responsiveCardWidth(viewportWidth);
    final isExpanded = ResponsiveUtils.isExpanded(context);

    if (isExpanded) {
      final columns = ResponsiveUtils.responsiveGridColumns(viewportWidth);
      return Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              itemCount: events.length,
              itemBuilder: (_, index) => _Featured(
                event: events[index],
                savedEventsRepository: savedEventsRepository,
                authRepository: authRepository,
                socialRepository: socialRepository,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 360,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) => SizedBox(
          width: cardWidth,
          child: _Featured(
            event: events[index],
            savedEventsRepository: savedEventsRepository,
            authRepository: authRepository,
            socialRepository: socialRepository,
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
    required this.authRepository,
    required this.socialRepository,
  });

  final EventModel event;
  final SavedEventsRepository savedEventsRepository;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;

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
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: .08),
      child: InkWell(
        onTap: () => context.push('/event/${event.id}', extra: event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _Artwork(event: event, height: 180),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child:
                        _Pill(value: event.categoryLabel ?? event.categoryId),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShareEventButton(event: event, size: 36),
                        const SizedBox(width: 6),
                        SaveHeartButton(
                          eventId: event.id,
                          repository: savedEventsRepository,
                          authRepository: authRepository,
                          size: 36,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.name.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PriceChip(event: event),
                      ],
                    ),
                    EventSocialRow(
                      eventId: event.id,
                      socialRepository: socialRepository,
                      isSignedIn: authRepository.isSignedIn,
                    ),
                    const SizedBox(height: 12),
                    _Meta(
                      icon: Icons.location_on_outlined,
                      text: event.venue?.address?.city ?? 'Harare',
                    ),
                    const SizedBox(height: 4),
                    _Meta(
                      icon: Icons.schedule_rounded,
                      text: DateFormat('EEE, d MMM · HH:mm').format(date),
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
    required this.authRepository,
  });

  final EventModel event;
  final SavedEventsRepository savedEventsRepository;
  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    final date = _eventDate(event);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Stack(
        children: [
          InkWell(
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
                        Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: _Pill(
                            value: event.categoryLabel ?? event.categoryId,
                            compact: true,
                          ),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: SaveHeartButton(
              eventId: event.id,
              repository: savedEventsRepository,
              authRepository: authRepository,
              size: 34,
            ),
          ),
        ],
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

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final paid = event.ticketClasses.where((ticket) => !ticket.free).toList();
    final text = event.isFree
        ? 'Free'
        : paid.isEmpty
            ? 'Paid'
            : 'From ${paid.map((ticket) => ticket.cost?.display).whereType<String>().firstOrNull ?? ''}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.purple,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
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

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = ResponsiveUtils.responsiveCardWidth(viewportWidth);

    return Shimmer.fromColors(
      baseColor: AppColors.surfaceMuted,
      highlightColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              width: 120,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          SizedBox(
            height: 340,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => SizedBox(
                width: cardWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Container(
              width: 160,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
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
