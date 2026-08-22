import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/repositories/discovery_preferences_repository.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.preferencesRepository});
  final DiscoveryPreferencesRepository preferencesRepository;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  late String _city;
  late Set<String> _interests;
  bool _saving = false;

  static const _cities = ['Harare', 'Bulawayo', 'Victoria Falls', 'Mutare'];
  static const _interestsList = <(String, IconData)>[
    ('Music', Icons.music_note_rounded),
    ('Nightlife', Icons.nightlife_rounded),
    ('Performing & Visual Arts', Icons.palette_outlined),
    ('Food & Drink', Icons.restaurant_rounded),
    ('Business', Icons.business_center_outlined),
    ('Sports', Icons.sports_soccer_rounded),
    ('Holidays', Icons.flight_takeoff_rounded),
    ('Hobbies', Icons.sports_esports_outlined),
    ('Dating', Icons.favorite_border_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _city = widget.preferencesRepository.city;
    _interests = widget.preferencesRepository.interests.isEmpty
        ? {'Music', 'Performing & Visual Arts'}
        : widget.preferencesRepository.interests.toSet();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.preferencesRepository.save(city: _city, interests: _interests);
    if (mounted) context.go('/');
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page == 2) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(page: _page, onSkip: _finish),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: [
                    const _WelcomePage(),
                    _PreferencePage(
                      interests: _interests,
                      options: _interestsList,
                      onInterest: (value) => setState(() {
                        _interests.contains(value)
                            ? _interests.remove(value)
                            : _interests.add(value);
                      }),
                    ),
                    _LocationPage(
                      city: _city,
                      cities: _cities,
                      onCity: (value) => setState(() => _city = value),
                    ),
                  ],
                ),
              ),
              _BottomBar(
                page: _page,
                enabled: _page != 1 || _interests.length >= 2,
                saving: _saving,
                onBack: () => _controller.previousPage(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                ),
                onNext: _next,
              ),
            ],
          ),
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.page, required this.onSkip});
  final int page;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 14, 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: AppGradients.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 19),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('FUTURE TIMES',
                  style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1)),
            ),
            TextButton(onPressed: onSkip, child: const Text('Skip for now')),
          ],
        ),
      );
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) => const _PageFrame(
        visual: _DiscoveryVisual(),
        eyebrow: 'FUTURE TIMES EVENTS',
        title: "Find what's happening\naround you.",
        body:
            'Discover the concerts, culture, food, sport and ideas shaping Zimbabwe—curated around you, not a generic popularity list.',
        trust: 'Real organisers  •  Secure tickets  •  Local discovery',
      );
}

class _PreferencePage extends StatelessWidget {
  const _PreferencePage({
    required this.interests,
    required this.options,
    required this.onInterest,
  });
  final Set<String> interests;
  final List<(String, IconData)> options;
  final ValueChanged<String> onInterest;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Eyebrow('MAKE IT YOURS'),
              const SizedBox(height: 12),
              Text('What are you into?',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 38, height: 1.02, letterSpacing: -1.4)),
              const SizedBox(height: 12),
              const Text(
                'Choose at least two interests. You can change these anytime.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final option in options)
                    FilterChip(
                      selected: interests.contains(option.$1),
                      onSelected: (_) => onInterest(option.$1),
                      avatar: Icon(option.$2,
                          size: 18,
                          color: interests.contains(option.$1)
                              ? Colors.white
                              : AppColors.purple),
                      label: Text(option.$1),
                      labelStyle: TextStyle(
                        color: interests.contains(option.$1)
                            ? Colors.white
                            : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedColor: AppColors.purple,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: interests.contains(option.$1)
                            ? AppColors.purple
                            : AppColors.border,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      showCheckmark: false,
                    ),
                ],
              ),
            ]),
          ),
        ),
      );
}

class _LocationPage extends StatelessWidget {
  const _LocationPage(
      {required this.city, required this.cities, required this.onCity});
  final String city;
  final List<String> cities;
  final ValueChanged<String> onCity;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow('DISCOVER NEARBY'),
                const SizedBox(height: 12),
                Text('Where should we look?',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 38, height: 1.02, letterSpacing: -1.4)),
                const SizedBox(height: 12),
                const Text(
                  'Choose your home city now. You can use precise location later from the Map, only when you ask us to.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 28),
                RadioGroup<String>(
                  groupValue: city,
                  onChanged: (selected) {
                    if (selected != null) onCity(selected);
                  },
                  child: Column(
                    children: [
                      for (final value in cities)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RadioListTile<String>(
                            value: value,
                            title: Text(value,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            subtitle: const Text('Zimbabwe'),
                            secondary: const Icon(Icons.location_city_rounded,
                                color: AppColors.purple),
                            tileColor: city == value
                                ? AppColors.purple.withValues(alpha: .08)
                                : AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: city == value
                                      ? AppColors.purple
                                      : AppColors.border),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Row(children: [
                  Icon(Icons.notifications_none_rounded,
                      color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We will ask about event reminders later, when the benefit is clear.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );
}

class _PageFrame extends StatelessWidget {
  const _PageFrame(
      {required this.visual,
      required this.eyebrow,
      required this.title,
      required this.body,
      required this.trust});
  final Widget visual;
  final String eyebrow;
  final String title;
  final String body;
  final String trust;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        final wide = size.maxWidth >= 780;
        final content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow(eyebrow),
            const SizedBox(height: 14),
            Text(title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: wide ? 54 : 42, height: .98, letterSpacing: -2)),
            const SizedBox(height: 18),
            Text(body,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.55)),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.verified_user_outlined,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(trust,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4))),
            ]),
          ],
        );
        if (wide) {
          return Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
              child: Row(children: [
                Expanded(child: visual),
                const SizedBox(width: 70),
                Expanded(child: content)
              ]),
            ),
          ));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(children: [
            SizedBox(height: 270, child: visual),
            const SizedBox(height: 28),
            content
          ]),
        );
      });
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Text(value,
      style: const TextStyle(
          color: AppColors.purple,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5));
}

class _DiscoveryVisual extends StatelessWidget {
  const _DiscoveryVisual();
  @override
  Widget build(BuildContext context) => const _VisualStage(children: [
        Positioned(
            left: 8,
            right: 62,
            top: 24,
            bottom: 28,
            child: _EventPoster(
              color: Color(0xFF23143D),
              icon: Icons.graphic_eq_rounded,
              category: 'LIVE • HARARE',
              title: 'WHAT\'S\nNEXT',
              subtitle: 'FRIDAY  •  20:00',
            )),
        Positioned(
            right: 8,
            top: 4,
            child: _FloatBadge(
                icon: Icons.explore_rounded,
                title: 'Discover locally',
                detail: 'Built around you')),
        Positioned(
            right: 0,
            bottom: 8,
            child: _FloatBadge(
                icon: Icons.verified_outlined,
                title: 'Real events',
                detail: 'Trusted details')),
      ]);
}

// Kept as a reusable branded ticket illustration for future contextual prompts.
// ignore: unused_element
class _TicketVisual extends StatelessWidget {
  const _TicketVisual();
  @override
  Widget build(BuildContext context) => _VisualStage(children: [
        Positioned(
            left: 12,
            right: 40,
            top: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF171322),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x337222E3),
                      blurRadius: 34,
                      offset: Offset(0, 16))
                ],
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.pink),
                      Spacer(),
                      Text('ADMIT ONE',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800))
                    ]),
                    const Spacer(),
                    const Text('CITY\nSUNDAYS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            height: .95,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    Container(height: 1, color: Colors.white12),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Text('24 AUG  •  14:00',
                          style: TextStyle(
                              color: AppColors.pink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                      Spacer(),
                      Icon(Icons.qr_code_2_rounded,
                          color: Colors.white, size: 36)
                    ]),
                  ]),
            )),
        const Positioned(
            right: 0,
            top: 0,
            child: _FloatBadge(
                icon: Icons.notifications_active_outlined,
                title: 'Doors in 1 hour',
                detail: 'Right on time')),
      ]);
}

class _VisualStage extends StatelessWidget {
  const _VisualStage({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: const RadialGradient(
              colors: [Color(0x297222E3), Colors.transparent]),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Stack(clipBehavior: Clip.none, children: children),
      );
}

class _EventPoster extends StatelessWidget {
  const _EventPoster(
      {required this.color,
      required this.icon,
      required this.category,
      required this.title,
      required this.subtitle});
  final Color color;
  final IconData icon;
  final String category;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x2E1A0C2E),
                  blurRadius: 38,
                  offset: Offset(0, 18))
            ]),
        child: Stack(children: [
          Positioned(
              right: -18,
              top: -10,
              child: Icon(icon,
                  color: AppColors.pink.withValues(alpha: .34), size: 150)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(category,
                style: const TextStyle(
                    color: AppColors.pink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2)),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    height: .88,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1)),
            const SizedBox(height: 13),
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
          ]),
        ]),
      );
}

class _FloatBadge extends StatelessWidget {
  const _FloatBadge(
      {required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x1F0A0A14),
                  blurRadius: 22,
                  offset: Offset(0, 9))
            ]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .1),
                  shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.purple, size: 18)),
          const SizedBox(width: 9),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
            Text(detail,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 9)),
          ]),
        ]),
      );
}

class _BottomBar extends StatelessWidget {
  const _BottomBar(
      {required this.page,
      required this.enabled,
      required this.saving,
      required this.onBack,
      required this.onNext});
  final int page;
  final bool enabled;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
        decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border))),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Row(children: [
            if (page > 0)
              IconButton(
                  onPressed: onBack,
                  tooltip: 'Previous',
                  icon: const Icon(Icons.arrow_back_rounded))
            else
              const SizedBox(width: 48),
            const SizedBox(width: 10),
            Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: index == page ? 24 : 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                  color: index == page
                                      ? AppColors.purple
                                      : AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(99)),
                            )))),
            SizedBox(
                width: 176,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                  onPressed: enabled && !saving ? onNext : null,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(saving
                            ? 'Opening…'
                            : page == 2
                                ? 'Explore events'
                                : page == 0
                                    ? 'Get Started'
                                    : 'Continue'),
                        if (!saving) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18)
                        ],
                      ]),
                )),
          ]),
        )),
      );
}
