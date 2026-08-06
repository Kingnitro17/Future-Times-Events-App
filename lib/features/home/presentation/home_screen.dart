import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/events/data/event_repository.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/ft_widgets.dart';
import '../../../shared/widgets/event_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = EventRepository();
  List<Event> _featured = [];
  List<Event> _upcoming = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final featured = await _repo.getFeaturedEvents(limit: 5);
      final upcoming = await _repo.getEvents(pageSize: 10);
      if (mounted) {
        setState(() {
          _featured = featured;
          _upcoming = upcoming;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: RefreshIndicator(
        color: AppColors.violet,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────────────────
            _HomeAppBar(),

            if (_loading) ...[
              SliverToBoxAdapter(
                child: _SkeletonHomeContent(),
              ),
            ] else if (_error != null) ...[
              SliverFillRemaining(
                child: FtErrorState(
                  message: 'Could not load events. Pull down to retry.',
                  onRetry: _loadData,
                ),
              ),
            ] else ...[
              // ── Featured Hero ──────────────────────────────────────────────
              if (_featured.isNotEmpty)
                SliverToBoxAdapter(
                  child: _FeaturedHero(events: _featured),
                ),

              // ── Browse by category ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _CategoryRow(),
              ),

              // ── Upcoming Events header ─────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Upcoming Events', style: AppTypography.h3),
                      TextButton(
                        onPressed: () => context.go('/events'),
                        child: Text(
                          'See all',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.violet,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Event list ─────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                sliver: _upcoming.isEmpty
                    ? SliverToBoxAdapter(
                        child: FtEmptyState(
                          message: 'No upcoming events right now.\nCheck back soon!',
                          icon: Icons.event_busy_rounded,
                        ),
                      )
                    : SliverList.separated(
                        itemCount: _upcoming.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) => EventCard(event: _upcoming[i])
                            .animate()
                            .fadeIn(
                              duration: 400.ms,
                              delay: Duration(milliseconds: i * 60),
                            )
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 400.ms,
                              delay: Duration(milliseconds: i * 60),
                            ),
                      ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: AppSpacing.xxl),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── App Bar ─────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          // Logo
          Image.asset(
            'assets/images/logo.png',
            height: 32,
            errorBuilder: (_, __, ___) => const FtGradientText(
              'FT',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FtGradientText(
              'Future Times',
              style: AppTypography.h4.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.text),
          onPressed: () => context.go('/events'),
          tooltip: 'Search events',
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

// ── Featured Hero Carousel ───────────────────────────────────────────────────

class _FeaturedHero extends StatefulWidget {
  const _FeaturedHero({required this.events});
  final List<Event> events;

  @override
  State<_FeaturedHero> createState() => _FeaturedHeroState();
}

class _FeaturedHeroState extends State<_FeaturedHero> {
  final _ctrl = PageController(viewportFraction: 0.9);
  int _current = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Text('Featured Events', style: AppTypography.h3),
        ),
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.events.length,
            itemBuilder: (_, i) {
              final event = widget.events[i];
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _HeroCard(event: event),
              );
            },
          ),
        ),
        // Dots
        if (widget.events.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: List.generate(
                widget.events.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: i == _current ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: i == _current
                        ? AppColors.violet
                        : AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/events/${event.slug}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          gradient: AppGradients.forCategory(event.category),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            if (event.bestImageUrl != null)
              CachedNetworkImage(
                imageUrl: event.bestImageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            // Dark overlay
            DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.heroDark),
            ),
            // Text content
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FtBadge(
                    label: event.categoryLabel.isNotEmpty
                        ? event.categoryLabel
                        : event.category,
                    variant: FtBadgeVariant.info,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    event.title,
                    style: AppTypography.h3.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('EEE, d MMM').format(event.startsAt)} · ${event.venueName}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  static const _categories = [
    ('🎵', 'Music', 'music'),
    ('🎨', 'Arts', 'arts'),
    ('🍽️', 'Food', 'food'),
    ('⚽', 'Sports', 'sports'),
    ('💻', 'Tech', 'tech'),
    ('😂', 'Comedy', 'comedy'),
    ('👗', 'Fashion', 'fashion'),
    ('💼', 'Business', 'business'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
          child: Text('Browse by Interest', style: AppTypography.h3),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.sm),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final (emoji, label, category) = _categories[i];
              return _CategoryChip(
                emoji: emoji,
                label: label,
                onTap: () => context.go('/events?category=$category'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(label, style: AppTypography.overline),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading ─────────────────────────────────────────────────────────

class _SkeletonHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FtSkeleton(width: 160, height: 22),
          const SizedBox(height: AppSpacing.md),
          const FtSkeleton(width: double.infinity, height: 240, borderRadius: 24),
          const SizedBox(height: AppSpacing.xl),
          const FtSkeleton(width: 140, height: 22),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < 3; i++) ...[
            FtSkeleton(width: double.infinity, height: 200 + i * 10.0, borderRadius: 24),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
