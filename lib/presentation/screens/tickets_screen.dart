import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/wallet_ticket.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/ticket_repository.dart';
import '../widgets/event_network_image.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.authRepository});
  final AuthRepository authRepository;
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  late final TicketRepository _repository;
  Future<List<WalletTicket>>? _future;
  String _filter = 'Upcoming';

  @override
  void initState() {
    super.initState();
    _repository = TicketRepository(authRepository: widget.authRepository);
    widget.authRepository.addListener(_authChanged);
    _refresh();
  }

  void _authChanged() {
    if (mounted) _refresh();
  }

  void _refresh() => setState(() {
        _future = _repository.getMyTickets();
      });

  @override
  void dispose() {
    widget.authRepository.removeListener(_authChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authRepository.isSignedIn ||
        widget.authRepository.isQaMockSession) {
      return const _SignedOut();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: FutureBuilder<List<WalletTicket>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _TicketSkeleton();
          }
          if (snapshot.hasError) return _TicketError(onRetry: _refresh);
          final all = snapshot.data ?? const [];
          final tickets = all
              .where((ticket) =>
                  (_filter == 'Upcoming' && ticket.isActive) ||
                  (_filter == 'Past' && !ticket.isActive))
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _future;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: _Filters(
                        value: _filter,
                        onChanged: (value) => setState(() => _filter = value))),
                if (tickets.isEmpty)
                  const SliverFillRemaining(
                      hasScrollBody: false, child: _EmptyTickets())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                    sliver: SliverList.separated(
                      itemCount: tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, index) =>
                          _TicketCard(ticket: tickets[index]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'Upcoming', label: Text('Upcoming')),
            ButtonSegment(value: 'Past', label: Text('Past')),
          ],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
          style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(0, 54)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)))),
        ),
      );
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});
  final WalletTicket ticket;
  @override
  Widget build(BuildContext context) {
    final color = ticket.isActive
        ? AppColors.success
        : ticket.isUsed
            ? AppColors.purple
            : AppColors.textMuted;
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border)),
      child: InkWell(
          onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => _TicketDetail(ticket: ticket)),
          child: Column(children: [
            SizedBox(
                height: 156,
                width: double.infinity,
                child: Stack(fit: StackFit.expand, children: [
                  EventNetworkImage(
                      url: ticket.imageUrl,
                      semanticLabel: '${ticket.eventTitle} artwork'),
                  const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Colors.transparent, Color(0xB8000000)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter))),
                  Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Text(ticket.eventTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w900))),
                ])),
            Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            ticket.eventStart == null
                                ? 'Date TBA'
                                : DateFormat('EEE, d MMM · h:mm a')
                                    .format(ticket.eventStart!),
                            style: const TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text('${ticket.ticketType} · ${ticket.venue}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 7),
                        Text(ticket.ticketNumber,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontFeatures: [FontFeature.tabularFigures()])),
                      ])),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(_status(ticket.status),
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800))),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more_rounded,
                      color: AppColors.textMuted),
                ])),
          ])),
    );
  }
}

class _TicketDetail extends StatelessWidget {
  const _TicketDetail({required this.ticket});
  final WalletTicket ticket;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('FUTURE TIMES',
            style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4)),
        const SizedBox(height: 16),
        Text(ticket.eventTitle,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        _DetailRow('Ticket', ticket.ticketType),
        _DetailRow('Holder', ticket.attendeeName),
        _DetailRow('Reference', ticket.ticketNumber),
        _DetailRow('Venue', ticket.venue),
        _DetailRow('Status', _status(ticket.status)),
        if (ticket.checkedInAt != null)
          _DetailRow('Checked in',
              DateFormat('d MMM yyyy · h:mm a').format(ticket.checkedInAt!)),
        const SizedBox(height: 20),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(18)),
            child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.purple),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'Secure QR access is shown only when the one-time '
                          'claim token is available on this device. Ticket references are never '
                          'converted into fake QR codes.')),
                ])),
      ]));
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 92,
            child: Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w700))),
      ]));
}

String _status(String value) => switch (value) {
      'issued' => 'Active',
      'checked_in' => 'Checked In',
      'cancelled' => 'Cancelled',
      'revoked' => 'Revoked',
      _ => value,
    };

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets();
  @override
  Widget build(BuildContext context) => _EmptyState(
      icon: Icons.confirmation_number_outlined,
      title: 'Your tickets',
      detail: 'When you book events, your tickets will appear here.',
      primaryLabel: 'Explore Events',
      onPrimary: () => context.go('/explore'));
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();
  @override
  Widget build(BuildContext context) => Scaffold(
      body: _EmptyState(
          icon: Icons.confirmation_number_outlined,
          title: 'Your tickets',
          detail: 'Book an event or sign in to sync tickets from your account.',
          primaryLabel: 'Explore Events',
          onPrimary: () => context.go('/explore'),
          secondaryLabel: 'Sign in',
          onSecondary: () => context.go('/profile')));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.detail,
      this.primaryLabel,
      this.onPrimary,
      this.secondaryLabel,
      this.onSecondary});
  final IconData icon;
  final String title;
  final String detail;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: .07),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.purple.withValues(alpha: .14))),
                child: Icon(icon, size: 48, color: AppColors.purple)),
            const SizedBox(height: 24),
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 16, height: 1.5)),
            if (primaryLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed: onPrimary,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  iconAlignment: IconAlignment.end,
                  label: Text(primaryLabel!)),
            ],
            if (secondaryLabel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ])));
}

class _TicketSkeleton extends StatelessWidget {
  const _TicketSkeleton();
  @override
  Widget build(BuildContext context) => ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
          height: 270,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(22))));
}

class _TicketError extends StatelessWidget {
  const _TicketError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined,
            size: 54, color: AppColors.textMuted),
        const SizedBox(height: 12),
        const Text('Your tickets are unavailable.'),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ]));
}
