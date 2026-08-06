import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/event_repository.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/ft_widgets.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _repo = EventRepository();
  Event? _event;
  List<TicketType> _ticketTypes = [];
  List<Map<String, dynamic>> _faqs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final event = await _repo.getEventBySlug(widget.slug);
      if (event == null) {
        setState(() { _error = 'Event not found.'; _loading = false; });
        return;
      }
      final ticketTypes = await _repo.getTicketTypes(event.id);
      final faqs = await _repo.getEventFaqs(event.id);
      if (mounted) {
        setState(() {
          _event = event;
          _ticketTypes = ticketTypes;
          _faqs = faqs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _EventDetailSkeleton();
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: FtErrorState(message: _error!, onRetry: _load),
      );
    }
    final event = _event!;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.bestImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: event.bestImageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.forCategory(event.category),
                        ),
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppGradients.forCategory(event.category),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(gradient: AppGradients.heroDark),
                  ),
                ],
              ),
            ),
          ),

          // ── Event content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + status
                  Row(
                    children: [
                      FtBadge(
                        label: event.categoryLabel.isNotEmpty
                            ? event.categoryLabel
                            : event.category,
                        variant: FtBadgeVariant.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (event.isSoldOut)
                        const FtBadge(
                            label: 'Sold Out', variant: FtBadgeVariant.error),
                      if (event.featured)
                        const FtBadge(
                            label: 'Featured', variant: FtBadgeVariant.warning),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: AppSpacing.md),

                  // Title
                  Text(event.title, style: AppTypography.h1)
                      .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                  if (event.subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(event.subtitle!, style: AppTypography.body),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // ── Info cards ─────────────────────────────────────────────
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    title: DateFormat('EEEE, d MMMM y').format(event.startsAt),
                    subtitle:
                        '${DateFormat('h:mm a').format(event.startsAt)}${event.endsAt != null ? ' – ${DateFormat('h:mm a').format(event.endsAt!)}' : ''}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    title: event.venueName.isNotEmpty
                        ? event.venueName
                        : 'Venue TBA',
                    subtitle: event.city.isNotEmpty ? event.city : null,
                    onTap: (event.lat != null && event.lng != null)
                        ? () => launchUrl(Uri.parse(
                            'https://maps.google.com/?q=${event.lat},${event.lng}'))
                        : null,
                  ),
                  if (event.dressCode != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: Icons.checkroom_rounded,
                      title: 'Dress Code',
                      subtitle: event.dressCode,
                    ),
                  ],
                  if (event.ageGuidance != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: Icons.person_rounded,
                      title: 'Age',
                      subtitle: event.ageGuidance,
                    ),
                  ],

                  // ── About ────────────────────────────────────────────────
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('About', style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      event.longDescription.isNotEmpty
                          ? event.longDescription
                          : event.description,
                      style: AppTypography.body,
                    ),
                  ],

                  // ── Ticket Types summary ────────────────────────────────
                  if (_ticketTypes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('Tickets', style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    ..._ticketTypes.map((t) => _TicketTypeTile(type: t)),
                  ],

                  // ── FAQs ────────────────────────────────────────────────
                  if (_faqs.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text('FAQs', style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    ..._faqs.map((faq) => _FaqTile(
                          question: faq['question'] as String? ?? '',
                          answer: faq['answer'] as String? ?? '',
                        )),
                  ],

                  // Bottom spacer (above sticky button)
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky CTA ────────────────────────────────────────────────────────
      bottomNavigationBar: _EventBottomBar(event: _event!, slug: widget.slug),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.violet.withAlpha(18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 20, color: AppColors.violet),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium),
                if (subtitle != null)
                  Text(subtitle!, style: AppTypography.caption),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _TicketTypeTile extends StatelessWidget {
  const _TicketTypeTile({required this.type});
  final TicketType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.name, style: AppTypography.bodyMedium),
                if (type.description.isNotEmpty)
                  Text(type.description, style: AppTypography.caption),
                Text(
                  '${type.quantityAvailable} left',
                  style: AppTypography.caption.copyWith(
                    color: type.quantityAvailable < 20
                        ? AppColors.warning
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            type.isFree ? 'FREE' : 'USD ${type.price.toStringAsFixed(0)}',
            style: AppTypography.price.copyWith(
              fontSize: 18,
              color: type.isFree ? AppColors.success : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(question, style: AppTypography.bodyMedium),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          child: Text(answer, style: AppTypography.body),
        ),
      ],
    );
  }
}

class _EventBottomBar extends StatelessWidget {
  const _EventBottomBar({required this.event, required this.slug});
  final Event event;
  final String slug;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: FtGradientButton(
          label: event.isSoldOut
              ? 'Sold Out'
              : event.isSalesOpen
                  ? 'Get Tickets'
                  : 'Sales Closed',
          onPressed: (event.isSalesOpen && !event.isSoldOut)
              ? () => context.go('/events/$slug/tickets')
              : null,
          gradient: event.isSoldOut ? null : AppGradients.primary,
        ),
      ),
    );
  }
}

class _EventDetailSkeleton extends StatelessWidget {
  const _EventDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const FtSkeleton(width: double.infinity, height: 300),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FtSkeleton(width: 80, height: 24, borderRadius: 99),
                  const SizedBox(height: AppSpacing.md),
                  const FtSkeleton(width: double.infinity, height: 36),
                  const SizedBox(height: AppSpacing.sm),
                  const FtSkeleton(width: 200, height: 20),
                  const SizedBox(height: AppSpacing.xl),
                  const FtSkeleton(width: double.infinity, height: 80, borderRadius: 12),
                  const SizedBox(height: AppSpacing.md),
                  const FtSkeleton(width: double.infinity, height: 80, borderRadius: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
