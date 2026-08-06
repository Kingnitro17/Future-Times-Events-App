import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../logic/blocs/booking/booking_bloc.dart';
import '../../logic/blocs/booking/booking_event.dart';
import '../../logic/blocs/social/social_bloc.dart';
import '../../logic/blocs/social/social_event.dart';
import '../../logic/blocs/social/social_state.dart';
import '../widgets/adaptive_button.dart';
import '../widgets/glassmorphism_card.dart';
import 'booking_screen.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.event});
  final EventModel event;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  TicketClass? _selectedTicket;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    context.read<SocialBloc>().add(WatchAttendees(eventId: widget.event.id));
    final available =
        widget.event.ticketClasses.where((t) => !t.hidden).toList();
    if (available.isNotEmpty) _selectedTicket = available.first;
  }

  String get _date => DateFormat('EEEE, MMMM d, y')
      .format(DateTime.parse(widget.event.start.local));

  String get _time {
    final s = DateTime.parse(widget.event.start.local);
    final e = DateTime.parse(widget.event.end.local);
    return '${DateFormat.jm().format(s)} — ${DateFormat.jm().format(e)}';
  }

  String get _imageUrl =>
      widget.event.logo?.original?.url ?? widget.event.logo?.url ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      body: CustomScrollView(
        slivers: [
          _heroAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _title(),
                const SizedBox(height: 24),
                _infoCard(Icons.calendar_month_rounded, _date, _time),
                const SizedBox(height: 12),
                _infoCard(
                  widget.event.isOnlineEvent
                      ? Icons.videocam_rounded
                      : Icons.location_on_rounded,
                  widget.event.venue?.name ??
                      (widget.event.isOnlineEvent ? 'Online' : 'TBA'),
                  widget.event.venue?.address?.localizedDisplay ?? '',
                  onTap: widget.event.venue != null &&
                          widget.event.venue?.latitude != null
                      ? () => context.push('/event/${widget.event.id}/map',
                          extra: widget.event)
                      : null,
                ),
                const SizedBox(height: 28),
                _description(),
                const SizedBox(height: 28),
                _whoIsGoing(),
                const SizedBox(height: 28),
                _ticketSelector(),
              ].animate(interval: 60.ms).fade(duration: 400.ms).slideY(
                  begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _cta(),
    );
  }

  Widget _heroAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppTheme.charcoal,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const GlassmorphismCard(
            padding: EdgeInsets.all(8),
            blur: 12,
            child: Icon(Icons.arrow_back_rounded,
                color: AppTheme.pureWhite, size: 20),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'event_${widget.event.id}',
          child: Stack(fit: StackFit.expand, children: [
            if (_imageUrl.isNotEmpty)
              CachedNetworkImage(imageUrl: _imageUrl, fit: BoxFit.cover)
            else
              Container(
                  color: AppTheme.charcoalSurface,
                  child: const Icon(Icons.event_rounded,
                      size: 80, color: AppTheme.charcoalBorder)),
            const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.heroGradient)),
          ]),
        ),
      ),
    );
  }

  Widget _title() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.event.isFree)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.15),
            borderRadius: AppTheme.radiusPill,
            border: Border.all(color: AppTheme.successGreen.withOpacity(0.4)),
          ),
          child: const Text('FREE EVENT',
              style: TextStyle(
                  color: AppTheme.successGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ),
      Text(widget.event.name.text,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
    ]);
  }

  Widget _infoCard(IconData icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppTheme.charcoalCard,
          borderRadius: AppTheme.radiusMedium,
          border: Border.all(color: AppTheme.charcoalBorder)),
      child: Row(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppTheme.electricIndigo.withOpacity(0.15),
                borderRadius: AppTheme.radiusSmall),
            child: Icon(icon, color: AppTheme.electricIndigo, size: 22)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.pureWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    const TextStyle(color: AppTheme.subtleGrey, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ])),
      ]),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  Widget _description() {
    final desc = widget.event.description?.text ?? '';
    if (desc.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('About', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Text(desc,
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: 6,
          overflow: TextOverflow.ellipsis),
    ]);
  }

  Widget _whoIsGoing() {
    return BlocBuilder<SocialBloc, SocialState>(builder: (context, state) {
      if (state is! SocialLoaded) return const SizedBox.shrink();
      final attendees = state.attendees;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text("Who's Going", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: AppTheme.electricIndigo.withOpacity(0.15),
                borderRadius: AppTheme.radiusPill),
            child: Text('${attendees.length}',
                style: const TextStyle(
                    color: AppTheme.electricIndigo,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 16),
        if (attendees.isEmpty)
          Text('Be the first to check in!',
              style: Theme.of(context).textTheme.bodyMedium)
        else
          SizedBox(
            height: 52,
            child: Stack(
              children: List.generate(attendees.length.clamp(0, 8), (i) {
                final a = attendees[i];
                return Positioned(
                  left: i * 36.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.charcoal, width: 2)),
                    child: ClipOval(
                      child: a.avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: a.avatarUrl!, fit: BoxFit.cover)
                          : Container(
                              color: AppTheme.electricIndigo,
                              child: Center(
                                  child: Text(
                                a.displayName.isNotEmpty
                                    ? a.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppTheme.pureWhite,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                              ))),
                    ),
                  ),
                );
              }),
            ),
          ),
      ]);
    });
  }

  Widget _ticketSelector() {
    final tickets = widget.event.ticketClasses.where((t) => !t.hidden).toList();
    if (tickets.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tickets', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      ...tickets.map((t) {
        final sel = _selectedTicket?.id == t.id;
        return GestureDetector(
          onTap: () => setState(() => _selectedTicket = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sel
                  ? AppTheme.electricIndigo.withOpacity(0.12)
                  : AppTheme.charcoalCard,
              borderRadius: AppTheme.radiusMedium,
              border: Border.all(
                  color:
                      sel ? AppTheme.electricIndigo : AppTheme.charcoalBorder,
                  width: sel ? 2 : 1),
            ),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(t.name,
                        style: const TextStyle(
                            color: AppTheme.pureWhite,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    if (t.cost != null)
                      Text(t.cost!.display,
                          style: const TextStyle(
                              color: AppTheme.subtleGrey, fontSize: 13)),
                  ])),
              if (sel)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.electricIndigo),
            ]),
          ),
        );
      }),
      if (_selectedTicket != null && !_selectedTicket!.free) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Text('Quantity',
              style: TextStyle(color: AppTheme.offWhite, fontSize: 14)),
          const Spacer(),
          _QuantityPicker(
              value: _quantity,
              onChanged: (v) => setState(() => _quantity = v)),
        ]),
      ],
    ]);
  }

  Widget _cta() {
    final t = _selectedTicket;
    final label = t == null
        ? 'No tickets available'
        : t.free
            ? 'Register — Free'
            : 'Book — ${t.cost?.display ?? ''} × $_quantity';
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewPadding.bottom + 16),
      decoration: const BoxDecoration(
        color: AppTheme.charcoalSurface,
        border: Border(top: BorderSide(color: AppTheme.charcoalBorder)),
      ),
      child: AdaptiveButton(
        label: label,
        disabled: t == null,
        icon: Icons.confirmation_number_rounded,
        onPressed: () {
          if (t == null) return;
          context.read<BookingBloc>().add(InitiateBooking(
              event: widget.event, selectedTicket: t, quantity: _quantity));
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<BookingBloc>(),
              child: BookingScreen(event: widget.event),
            ),
          ));
        },
      ),
    );
  }
}

class _QuantityPicker extends StatelessWidget {
  const _QuantityPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Btn(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text('$value',
              style: const TextStyle(
                  color: AppTheme.pureWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 18))),
      _Btn(
          icon: Icons.add_rounded,
          onTap: value < 10 ? () => onChanged(value + 1) : null),
    ]);
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.electricIndigo.withOpacity(0.15)
              : AppTheme.charcoalCard,
          borderRadius: AppTheme.radiusSmall,
          border: Border.all(
              color:
                  active ? AppTheme.electricIndigo : AppTheme.charcoalBorder),
        ),
        child: Icon(icon,
            size: 18,
            color: active ? AppTheme.electricIndigo : AppTheme.charcoalBorder),
      ),
    );
  }
}
