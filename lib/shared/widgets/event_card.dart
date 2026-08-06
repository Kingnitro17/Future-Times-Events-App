import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/ft_widgets.dart';

/// The primary event card displayed in lists and grids.
/// Matches the event card aesthetic from the website.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.compact = false,
  });

  final Event event;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Event: ${event.title}. ${event.venueName}. '
          '${DateFormat('EEEE, d MMMM').format(event.startsAt)}.',
      button: true,
      child: GestureDetector(
        onTap: onTap ?? () => context.go('/events/${event.slug}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ───────────────────────────────────────────────────────
              _EventCardImage(event: event, compact: compact),

              // ── Content ─────────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category pill
                    FtBadge(
                      label: event.categoryLabel.isNotEmpty
                          ? event.categoryLabel
                          : event.category,
                      variant: FtBadgeVariant.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Title
                    Text(
                      event.title,
                      style: compact
                          ? AppTypography.h4
                          : AppTypography.h3,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (!compact && event.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle!,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.sm),

                    // Date + Venue row
                    _EventMeta(event: event),

                    if (event.isSoldOut) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const FtBadge(
                        label: 'Sold Out',
                        variant: FtBadgeVariant.error,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCardImage extends StatelessWidget {
  const _EventCardImage({required this.event, required this.compact});
  final Event event;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.bestImageUrl;
    final gradient = AppGradients.forCategory(event.category);
    final height = compact ? 140.0 : 200.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: image or gradient fallback
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _GradientPlaceholder(gradient: gradient),
              errorWidget: (_, __, ___) =>
                  _GradientPlaceholder(gradient: gradient),
            )
          else
            _GradientPlaceholder(gradient: gradient),

          // Dark overlay for text legibility
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.heroDark,
            ),
          ),

          // Date chip (top-right)
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _DateChip(date: event.startsAt),
          ),

          // Featured badge (top-left)
          if (event.featured)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.fire,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '⚡ FEATURED',
                  style: AppTypography.overline.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.gradient});
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: gradient),
    child: const Center(
      child: Icon(Icons.event_rounded, size: 40, color: Colors.white54),
    ),
  );
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: const ColorFilter.mode(Colors.transparent, BlendMode.overlay),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(115),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('MMM').format(date).toUpperCase(),
                style: AppTypography.overline.copyWith(
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
              Text(
                DateFormat('d').format(date),
                style: AppTypography.h4.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventMeta extends StatelessWidget {
  const _EventMeta({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEE, d MMM · h:mm a').format(event.startsAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: AppColors.violet),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                dateStr,
                style: AppTypography.caption.copyWith(
                  color: AppColors.violet,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (event.venueName.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${event.venueName}${event.city.isNotEmpty ? ", ${event.city}" : ""}',
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
