import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_model.dart';

/// Premium event card with Hero animation, category badge,
/// date chip, and free/paid indicator.
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.heroTag,
  });

  final EventModel event;
  final VoidCallback onTap;
  final String? heroTag;

  String get _formattedDate {
    final dt = DateTime.parse(event.start.local);
    return DateFormat('EEE, MMM d · h:mm a').format(dt);
  }

  String get _location {
    if (event.isOnlineEvent) return 'Online Event';
    return event.venue?.address?.city ?? event.venue?.name ?? 'Location TBA';
  }

  String get _imageUrl => event.logo?.original?.url ?? event.logo?.url ?? '';

  bool get _hasImage => _imageUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final tag = heroTag ?? 'event_${event.id}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.charcoalCard,
          borderRadius: AppTheme.radiusLarge,
          border: Border.all(color: AppTheme.charcoalBorder),
          boxShadow: AppTheme.softShadow,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Image ────────────────────────────────────────────────
            Hero(
              tag: tag,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_hasImage)
                      CachedNetworkImage(
                        imageUrl: _imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _shimmerPlaceholder(),
                        errorWidget: (_, __, ___) => _imageFallback(),
                      )
                    else
                      _imageFallback(),

                    // Bottom gradient
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                        ),
                      ),
                    ),

                    // Free / Paid badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _PriceBadge(event: event),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.name.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.pureWhite,
                          height: 1.3,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Date row
                  _MetaRow(
                    icon: Icons.schedule_rounded,
                    text: _formattedDate,
                  ),
                  const SizedBox(height: 6),

                  // Location row
                  _MetaRow(
                    icon: event.isOnlineEvent
                        ? Icons.videocam_rounded
                        : Icons.location_on_rounded,
                    text: _location,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppTheme.charcoalCard,
      highlightColor: AppTheme.charcoalBorder,
      child: Container(color: AppTheme.charcoalCard),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppTheme.charcoalSurface,
      child: const Center(
        child: Icon(
          Icons.event_rounded,
          size: 48,
          color: AppTheme.charcoalBorder,
        ),
      ),
    );
  }
}

// ── Price Badge ─────────────────────────────────────────────────────────────

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.event});
  final EventModel event;

  @override
  Widget build(BuildContext context) {
    if (event.isFree) {
      return _badge('FREE', AppTheme.successGreen);
    }

    final lowestTicket = event.ticketClasses
        .where((t) => !t.hidden && !t.free)
        .fold<TicketClass?>(null, (prev, t) {
      if (prev == null) return t;
      return (t.cost?.value ?? 0) < (prev.cost?.value ?? 0) ? t : prev;
    });

    if (lowestTicket?.cost?.display != null) {
      return _badge(
          'From ${lowestTicket!.cost!.display}', AppTheme.electricIndigo);
    }

    return const SizedBox.shrink();
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppTheme.radiusPill,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.pureWhite,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Meta Row ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.electricIndigo),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.subtleGrey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────────────────────

class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.charcoalCard,
      highlightColor: AppTheme.charcoalBorder,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.charcoalCard,
          borderRadius: AppTheme.radiusLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(color: AppTheme.charcoalSurface),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.charcoalSurface,
                      borderRadius: AppTheme.radiusSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.charcoalSurface,
                      borderRadius: AppTheme.radiusSmall,
                    ),
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
