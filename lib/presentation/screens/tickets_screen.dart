import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/event_model.dart';
import '../../data/models/wallet_ticket.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/ticket_repository.dart';
import '../widgets/event_network_image.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/error_state.dart';
import '../widgets/common/premium_sheet.dart';
import '../widgets/common/skeleton.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.authRepository});
  final AuthRepository authRepository;
  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  late final TicketRepository _repository;
  late final EventRepository _eventRepository;
  final Map<String, String> _priceCache = {};
  Future<List<WalletTicket>>? _future;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _repository = TicketRepository(authRepository: widget.authRepository);
    _eventRepository = EventRepository();
    widget.authRepository.addListener(_authChanged);
    _refresh();
  }

  void _authChanged() {
    if (mounted) _refresh();
  }

  Future<String> _resolvePrice(WalletTicket ticket) async {
    final cached = _priceCache[ticket.id];
    if (cached != null) return cached;

    try {
      final event = await _eventRepository.getEventById(ticket.eventId);
      final match = event.ticketClasses.firstWhere(
        (entry) =>
            entry.name.toLowerCase() == ticket.ticketType.toLowerCase() ||
            entry.name.toLowerCase().contains(ticket.ticketType.toLowerCase()),
        orElse: () => const TicketClass(
          id: '',
          name: '',
          cost: EventCost(currency: 'USD', value: 0, display: 'Free'),
        ),
      );
      final value = match.cost?.display ?? (event.isFree ? 'Free' : 'Paid');
      _priceCache[ticket.id] = value;
      return value;
    } catch (_) {
      final fallback = ticket.ticketType.toLowerCase().contains('free')
          ? 'Free'
          : (ticket.ticketType.toLowerCase().contains('vip') ? 'Paid' : 'Free');
      _priceCache[ticket.id] = fallback;
      return fallback;
    }
  }

  void _refresh() => setState(() {
        _future = _repository.getMyTickets();
        _priceCache.clear();
      });

  @override
  void dispose() {
    widget.authRepository.removeListener(_authChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authRepository.isSignedIn) {
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
          final tickets = switch (_filter) {
            'Active' => all.where((ticket) => ticket.isActive).toList(),
            'Used' => all.where((ticket) => ticket.isUsed).toList(),
            _ => all,
          };
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
                      itemBuilder: (_, index) => _TicketCard(
                            ticket: tickets[index],
                            resolvePrice: _resolvePrice,
                          ),
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
            ButtonSegment(value: 'All', label: Text('All')),
            ButtonSegment(value: 'Active', label: Text('Active')),
            ButtonSegment(value: 'Used', label: Text('Used')),
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
  const _TicketCard({
    required this.ticket,
    required this.resolvePrice,
  });

  final WalletTicket ticket;
  final Future<String> Function(WalletTicket) resolvePrice;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => PremiumBottomSheet(
            child: _TicketDetail(ticket: ticket),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventNetworkImage(
                    url: ticket.imageUrl,
                    semanticLabel: '${ticket.eventTitle} artwork',
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xB8000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ticket.ticketType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.ticketType,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<String>(
                    future: resolvePrice(ticket),
                    builder: (context, snapshot) {
                      final value = snapshot.data ?? 'Free';
                      final isFree = value.toLowerCase() == 'free';
                      return Text(
                        value,
                        style: AppText.caption.copyWith(
                          color: isFree ? AppColors.textMuted : AppColors.purple,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bought ${_relative(ticket.issuedAt)}',
                    style: AppText.micro.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${ticket.eventTitle} • ${_eventShortDate(ticket.eventStart)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.micro.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => PremiumBottomSheet(
                          child: _TicketDetail(ticket: ticket),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            AppColors.purple.withValues(alpha: 0.08),
                        foregroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View QR'),
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
        if (ticket.gate != null && ticket.gate!.trim().isNotEmpty)
          _DetailRow('Gate', ticket.gate!),
        const SizedBox(height: 20),
        if (ticket.status != 'cancelled' && ticket.status != 'revoked') ...[
          Center(
            child: Semantics(
              label: 'Secure entry QR code for ${ticket.eventTitle}',
              image: true,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x100A0A14),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: ticket.effectiveQrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.text,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ticket.ticketNumber,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ticket.isUsed)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: AppColors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.purple, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Verified Entry · ${ticket.gate ?? 'Main Gate'}',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ticket.ticketNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reference copied to clipboard.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Ref'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: 'My ticket for ${ticket.eventTitle}\n'
                          'Ref: ${ticket.ticketNumber}\n'
                          'Venue: ${ticket.venue}',
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ] else
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(18)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.shield_outlined, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('This ticket has been ${ticket.status}. '
                        'Entry QR code is no longer active for this admission.')),
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

String _relative(DateTime date) {
  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
  if (difference.inDays < 1) return '${difference.inHours} hours ago';
  if (difference.inDays < 7) return '${difference.inDays} days ago';
  return DateFormat('MMM d, yyyy').format(date.toLocal());
}

String _eventShortDate(DateTime? date) {
  if (date == null) return 'Date TBA';
  return DateFormat('EEE, d MMM').format(date);
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
  Widget build(BuildContext context) => EmptyState(
      icon: Icons.confirmation_number_outlined,
      title: 'Your tickets',
      message: 'When you book events, your tickets will appear here.',
      actionLabel: 'Explore Events',
      onAction: () => context.go('/explore'));
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            Expanded(
              child: EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'Your tickets',
                message:
                    'Book an event or sign in to sync tickets from your account.',
                actionLabel: 'Explore Events',
                onAction: () => context.go('/explore'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton(
                onPressed: () => context.go('/profile'),
                child: const Text('Sign in'),
              ),
            ),
          ],
        ),
      );
}

class _TicketSkeleton extends StatelessWidget {
  const _TicketSkeleton();
  @override
  Widget build(BuildContext context) => ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: 3,
      itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: SkeletonBox(height: 270, radius: 22),
          ));
}

class _TicketError extends StatelessWidget {
  const _TicketError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => ErrorState(onRetry: onRetry);
}
