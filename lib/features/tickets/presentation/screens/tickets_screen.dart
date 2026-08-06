import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/ticket_repository.dart';
import '../../../shared/models/models.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/ft_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with SingleTickerStateMixin {
  final _repo = TicketRepository();
  late final TabController _tabs;
  List<Ticket> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() { _loading = true; _error = null; });
    try {
      final tickets = await _repo.getMyTickets();
      if (mounted) setState(() { _tickets = tickets; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Ticket> get _upcoming => _tickets
      .where((t) =>
          t.isValid &&
          (t.eventStartsAt?.isAfter(DateTime.now()) ?? true))
      .toList();

  List<Ticket> get _used =>
      _tickets.where((t) => t.isUsed).toList();

  List<Ticket> get _cancelled => _tickets
      .where((t) =>
          t.status == TicketStatus.cancelled ||
          t.status == TicketStatus.revoked)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: Text('My Tickets', style: AppTypography.h3.copyWith(color: AppColors.text)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.violet,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.violet,
          tabs: [
            Tab(text: 'Upcoming (${_upcoming.length})'),
            Tab(text: 'Used (${_used.length})'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _loading
          ? const _TicketsLoadingSkeleton()
          : _error != null
              ? FtErrorState(
                  message: 'Could not load your tickets.',
                  onRetry: _loadTickets,
                )
              : RefreshIndicator(
                  color: AppColors.violet,
                  onRefresh: _loadTickets,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _TicketList(
                        tickets: _upcoming,
                        emptyMessage: 'No upcoming tickets.\nFind events to get started!',
                        emptyAction: () => context.go('/events'),
                        emptyActionLabel: 'Browse Events',
                      ),
                      _TicketList(
                        tickets: _used,
                        emptyMessage: 'No used tickets yet.',
                      ),
                      _TicketList(
                        tickets: _cancelled,
                        emptyMessage: 'No cancelled tickets.',
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({
    required this.tickets,
    required this.emptyMessage,
    this.emptyAction,
    this.emptyActionLabel,
  });
  final List<Ticket> tickets;
  final String emptyMessage;
  final VoidCallback? emptyAction;
  final String? emptyActionLabel;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return FtEmptyState(
        message: emptyMessage,
        icon: Icons.confirmation_number_outlined,
        action: emptyAction,
        actionLabel: emptyActionLabel,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _TicketCard(ticket: tickets[i]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final gradient = AppGradients.forCategory('music'); // fallback
    final isValid = ticket.isValid;

    return GestureDetector(
      onTap: () => context.go('/tickets/${ticket.id}'),
      child: Semantics(
        label: 'Ticket for ${ticket.eventTitle ?? "event"}. '
            'Status: ${ticket.status.label}.',
        button: true,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Left: event image strip
              SizedBox(
                width: 90,
                height: 110,
                child: ticket.eventCoverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: ticket.eventCoverImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(gradient: gradient),
                        child: const Icon(Icons.event_rounded,
                            color: Colors.white54, size: 32),
                      ),
              ),

              // Right: ticket info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.eventTitle ?? 'Event',
                              style: AppTypography.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          FtBadge(
                            label: ticket.status.label,
                            variant: ticket.isValid
                                ? FtBadgeVariant.success
                                : ticket.isUsed
                                    ? FtBadgeVariant.info
                                    : FtBadgeVariant.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (ticket.eventStartsAt != null)
                        Text(
                          DateFormat('EEE, d MMM · h:mm a')
                              .format(ticket.eventStartsAt!),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.violet,
                          ),
                        ),
                      if (ticket.eventVenueName != null)
                        Text(
                          ticket.eventVenueName!,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.ticketNumber,
                        style: AppTypography.mono,
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketsLoadingSkeleton extends StatelessWidget {
  const _TicketsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) =>
          const FtSkeleton(width: double.infinity, height: 110, borderRadius: 24),
    );
  }
}
