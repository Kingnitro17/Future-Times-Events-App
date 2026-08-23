import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/zimbabwe_location.dart';
import '../../data/repositories/discovery_preferences_repository.dart';
import '../../data/repositories/zimbabwe_locations_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.preferencesRepository,
    this.locationsRepository = const ZimbabweLocationsRepository(),
  });

  final DiscoveryPreferencesRepository preferencesRepository;
  final ZimbabweLocationsRepository locationsRepository;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final TextEditingController _searchController = TextEditingController();

  int _page = 0;
  late String _city;
  double? _latitude;
  double? _longitude;
  late Set<String> _interests;

  bool _saving = false;
  bool _isLocating = false;
  bool _showAllLocations = false;
  String _searchQuery = '';
  String? _statusMessage;

  // Real supported Future Times event categories
  static const List<(String, IconData)> _categories = [
    ('Music', Icons.music_note_rounded),
    ('Concerts', Icons.confirmation_number_outlined),
    ('Sports', Icons.sports_soccer_rounded),
    ('Comedy', Icons.theater_comedy_outlined),
    ('Festivals', Icons.festival_outlined),
    ('Nightlife', Icons.nightlife_rounded),
    ('Business', Icons.business_center_outlined),
    ('Culture', Icons.palette_outlined),
    ('Community', Icons.groups_outlined),
    ('Family', Icons.family_restroom_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _city = widget.preferencesRepository.city.isEmpty
        ? 'Harare'
        : widget.preferencesRepository.city;
    _latitude = widget.preferencesRepository.latitude;
    _longitude = widget.preferencesRepository.longitude;
    _interests = widget.preferencesRepository.interests.isEmpty
        ? {'Music', 'Concerts', 'Festivals'}
        : widget.preferencesRepository.interests.toSet();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.preferencesRepository.save(
      city: _city,
      interests: _interests,
      latitude: _latitude,
      longitude: _longitude,
    );
    if (mounted) {
      context.go('/');
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page == 2) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    HapticFeedback.selectionClick();
    _controller.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
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
              _statusMessage =
                  'Location permission denied. Please select a city manually.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLocating = false;
            _statusMessage =
                'Location permission permanently denied in settings.';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final nearest = widget.locationsRepository.findNearestLocation(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _isLocating = false;
          _city = nearest.displayName;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _statusMessage = 'Resolved to nearest city: ${nearest.displayName}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocating = false;
          _statusMessage =
              'Could not determine location. Please select a city.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _page != 1 || _interests.length >= 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopNavigation(
              page: _page,
              onSkip: _finish,
              onSignIn: () => context.push('/auth/login'),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _WelcomeScreen(
                    onGetStarted: _next,
                    onSignIn: () => context.push('/auth/login'),
                  ),
                  _InterestsScreen(
                    selectedInterests: _interests,
                    categories: _categories,
                    onToggle: (interest) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_interests.contains(interest)) {
                          _interests.remove(interest);
                        } else {
                          _interests.add(interest);
                        }
                      });
                    },
                  ),
                  _LocationScreen(
                    selectedCity: _city,
                    isLocating: _isLocating,
                    statusMessage: _statusMessage,
                    showAllLocations: _showAllLocations,
                    searchQuery: _searchQuery,
                    searchController: _searchController,
                    locationsRepository: widget.locationsRepository,
                    onSelectCity: (cityName, {double? lat, double? lng}) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _city = cityName;
                        _latitude = lat;
                        _longitude = lng;
                      });
                    },
                    onUseMyLocation: _locateUser,
                    onToggleShowAll: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _showAllLocations = !_showAllLocations;
                      });
                    },
                  ),
                ],
              ),
            ),
            _BottomBar(
              page: _page,
              enabled: canProceed,
              saving: _saving,
              onBack: _previous,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Navigation Bar ───────────────────────────────────────────────────────

class _TopNavigation extends StatelessWidget {
  const _TopNavigation({
    required this.page,
    required this.onSkip,
    required this.onSignIn,
  });

  final int page;
  final VoidCallback onSkip;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(
        children: [
          // Small branded badge for screens 2 & 3
          if (page > 0) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'FUTURE TIMES',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.1,
              ),
            ),
          ],
          const Spacer(),
          if (page == 0)
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            )
          else
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
              ),
              child: const Text('Skip for now'),
            ),
        ],
      ),
    );
  }
}

// ── SCREEN 1: WELCOME ────────────────────────────────────────────────────────

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // Branded Android Logo Component - never crop, stretch, touch edge
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 240,
                        maxHeight: 120,
                      ),
                      child: Image.asset(
                        'assets/images/androidlogo.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Eyebrow
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'FUTURE TIMES EVENTS',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Find what's happening around you.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1.2,
                          color: AppColors.text,
                        ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Discover concerts, sports, festivals, nightlife, culture and experiences across Zimbabwe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppGradients.brand,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: onGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onSignIn,
                    child: const Text(
                      'Already have an account? Sign In',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── SCREEN 2: INTERESTS ──────────────────────────────────────────────────────

class _InterestsScreen extends StatelessWidget {
  const _InterestsScreen({
    required this.selectedInterests,
    required this.categories,
    required this.onToggle,
  });

  final Set<String> selectedInterests;
  final List<(String, IconData)> categories;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final count = selectedInterests.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MAKE IT YOURS',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What are you into?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                count < 2
                    ? 'Select at least 2 interests to personalize your feed.'
                    : 'Great choice! Select more or continue when ready.',
                style: TextStyle(
                  color: count < 2 ? AppColors.purple : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: count < 2 ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: categories.map((cat) {
                  final isSelected = selectedInterests.contains(cat.$1);
                  return GestureDetector(
                    onTap: () => onToggle(cat.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.brand : null,
                        color: isSelected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : AppColors.border,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.$2,
                            size: 18,
                            color:
                                isSelected ? Colors.white : AppColors.purple,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat.$1,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SCREEN 3: LOCATION ───────────────────────────────────────────────────────

class _LocationScreen extends StatelessWidget {
  const _LocationScreen({
    required this.selectedCity,
    required this.isLocating,
    required this.statusMessage,
    required this.showAllLocations,
    required this.searchQuery,
    required this.searchController,
    required this.locationsRepository,
    required this.onSelectCity,
    required this.onUseMyLocation,
    required this.onToggleShowAll,
  });

  final String selectedCity;
  final bool isLocating;
  final String? statusMessage;
  final bool showAllLocations;
  final String searchQuery;
  final TextEditingController searchController;
  final ZimbabweLocationsRepository locationsRepository;
  final Function(String name, {double? lat, double? lng}) onSelectCity;
  final VoidCallback onUseMyLocation;
  final VoidCallback onToggleShowAll;

  @override
  Widget build(BuildContext context) {
    final List<ZimbabweLocation> displayedLocations;
    if (showAllLocations || searchQuery.trim().isNotEmpty) {
      displayedLocations = locationsRepository.searchLocations(searchQuery);
    } else {
      displayedLocations = ZimbabweLocationsRepository.curatedMajorLocations;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DISCOVER NEARBY',
                style: TextStyle(
                  color: AppColors.purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Where do you want to discover events?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a city or town. You can change this anytime.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),

              // Quick Action Oval Pills: All Zimbabwe & Use My Location
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StadiumPill(
                    label: 'All Zimbabwe',
                    icon: Icons.public_rounded,
                    isSelected: selectedCity == 'All Zimbabwe',
                    onTap: () => onSelectCity('All Zimbabwe'),
                  ),
                  _StadiumPill(
                    label: isLocating ? 'Locating...' : '📍 Use my location',
                    icon: isLocating ? null : null,
                    isLoading: isLocating,
                    isSelected: false,
                    onTap: isLocating ? null : onUseMyLocation,
                  ),
                ],
              ),

              if (statusMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  statusMessage!,
                  style: TextStyle(
                    color: statusMessage!.startsWith('Resolved')
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // View all toggle & Search header
              Row(
                children: [
                  Text(
                    showAllLocations || searchQuery.isNotEmpty
                        ? 'All Zimbabwe Locations (${displayedLocations.length})'
                        : 'Major Cities & Towns',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onToggleShowAll,
                    icon: Icon(
                      showAllLocations
                          ? Icons.unfold_less_rounded
                          : Icons.travel_explore_rounded,
                      size: 18,
                    ),
                    label: Text(
                      showAllLocations ? 'Show major' : 'View all locations',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),

              if (showAllLocations || searchQuery.isNotEmpty) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search city or town (e.g. Vic, Bind, Sham)...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.purple),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: const BorderSide(
                          color: AppColors.purple, width: 2),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Oval City Stadium Pills
              if (displayedLocations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No matching Zimbabwe towns found.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: displayedLocations.map((loc) {
                    final isSelected = selectedCity == loc.displayName;
                    return _StadiumPill(
                      label: loc.displayName,
                      isSelected: isSelected,
                      onTap: () => onSelectCity(
                        loc.displayName,
                        lat: loc.latitude,
                        lng: loc.longitude,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stadium Oval Pill Widget ─────────────────────────────────────────────────

class _StadiumPill extends StatelessWidget {
  const _StadiumPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.brand : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.purple,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (isSelected && !isLoading) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Bottom Action Bar ────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.enabled,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final int page;
  final bool enabled;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: [
              if (page > 0)
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Previous',
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.text),
                )
              else
                const SizedBox(width: 48),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: index == page ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: index == page ? AppGradients.brand : null,
                        color:
                            index == page ? null : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 170,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    disabledBackgroundColor:
                        AppColors.purple.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: enabled && !saving ? onNext : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        saving
                            ? 'Saving...'
                            : page == 2
                                ? 'Explore events'
                                : page == 0
                                    ? 'Get Started'
                                    : 'Continue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (!saving) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 18, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
