import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/event_model.dart';
import '../../logic/blocs/social/social_bloc.dart';
import '../../logic/blocs/social/social_event.dart';
import '../../logic/blocs/social/social_state.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.event});
  final EventModel event;
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  TicketClass? _selectedTicket;
  bool _saved = false;

  DateTime get _start => DateTime.parse(widget.event.start.local);
  DateTime get _end => DateTime.parse(widget.event.end.local);
  String get _image =>
      widget.event.logo?.original?.url ?? widget.event.logo?.url ?? '';

  @override
  void initState() {
    super.initState();
    context.read<SocialBloc>().add(WatchAttendees(eventId: widget.event.id));
    final tickets = widget.event.ticketClasses.where((t) => !t.hidden);
    if (tickets.isNotEmpty) _selectedTicket = tickets.first;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _hero()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            sliver: SliverList.list(children: [
              _attendance(),
              const SizedBox(height: 26),
              _facts(),
              const SizedBox(height: 28),
              _map(),
              const SizedBox(height: 28),
              _about(),
              if (widget.event.ticketClasses.isNotEmpty) ...[
                const SizedBox(height: 28),
                _tickets(),
              ],
            ]),
          ),
        ]),
        bottomNavigationBar: _bottomBar(),
      );

  Widget _hero() => SizedBox(
        height: 382,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            bottom: 62,
            child: Hero(
              tag: 'event_${widget.event.id}',
              child: _image.isEmpty
                  ? Container(
                      decoration:
                          const BoxDecoration(gradient: AppGradients.brand),
                      child: const Center(
                          child: Icon(Icons.event_rounded,
                              size: 72, color: Colors.white)))
                  : CachedNetworkImage(
                      imageUrl: _image,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                              gradient: AppGradients.brand)),
                    ),
            ),
          ),
          Positioned.fill(
            bottom: 62,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
              Colors.black.withValues(alpha: .35),
              Colors.transparent
            ], begin: Alignment.topCenter, end: Alignment.center))),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 18,
            right: 18,
            child: Row(children: [
              _circleButton(Icons.arrow_back_rounded, () => context.pop()),
              const Spacer(),
              const Text('Event Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 8)])),
              const Spacer(),
              _circleButton(_saved ? Icons.bookmark : Icons.bookmark_border,
                  () => setState(() => _saved = !_saved)),
            ]),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: Container(
              constraints: const BoxConstraints(minHeight: 126),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x1A0A0A14),
                      blurRadius: 24,
                      offset: Offset(0, 10))
                ],
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.event.categoryId != null)
                          Text(_category(widget.event.categoryId!),
                              style: const TextStyle(
                                  color: AppColors.pink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(widget.event.name.text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(height: 1.15)),
                      ]),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: .11),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(_price,
                      style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ]),
      );

  Widget _circleButton(IconData icon, VoidCallback onPressed) => Container(
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: AppColors.text),
            tooltip: icon == Icons.arrow_back_rounded ? 'Back' : 'Save event'),
      );

  Widget _attendance() => BlocBuilder<SocialBloc, SocialState>(
        builder: (context, state) {
          final attendees = state is SocialLoaded ? state.attendees : const [];
          return Row(children: [
            SizedBox(
              width: attendees.isEmpty ? 46 : 94,
              height: 42,
              child: attendees.isEmpty
                  ? Container(
                      decoration: const BoxDecoration(
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.people_outline_rounded,
                          color: AppColors.purple))
                  : Stack(
                      children:
                          List.generate(attendees.take(3).length, (index) {
                        final attendee = attendees[index];
                        return Positioned(
                          left: index * 26,
                          child: CircleAvatar(
                            radius: 21,
                            backgroundColor: AppColors.purpleLight,
                            backgroundImage: attendee.avatarUrl == null
                                ? null
                                : CachedNetworkImageProvider(
                                    attendee.avatarUrl!),
                            child: attendee.avatarUrl == null
                                ? Text(attendee.displayName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                        );
                      }),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  attendees.isEmpty
                      ? 'Be the first to go'
                      : '+${attendees.length} Going',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
            ),
            SizedBox(
              height: 40,
              child: FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Event link ready to share.'))),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(82, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Invite'),
              ),
            ),
          ]);
        },
      );

  Widget _facts() => IntrinsicHeight(
        child: Row(children: [
          Expanded(
              child: _Fact(
                  icon: Icons.calendar_month_rounded,
                  title: DateFormat('dd MMM yyyy').format(_start),
                  line1: DateFormat('EEEE').format(_start),
                  line2:
                      '${DateFormat.jm().format(_start)} – ${DateFormat.jm().format(_end)}')),
          const VerticalDivider(width: 28),
          Expanded(
              child: _Fact(
                  icon: widget.event.isOnlineEvent
                      ? Icons.videocam_rounded
                      : Icons.location_on_rounded,
                  title: widget.event.isOnlineEvent
                      ? 'Online event'
                      : widget.event.venue?.name ?? 'Venue TBA',
                  line1: widget.event.venue?.address?.city ?? '',
                  line2: widget.event.venue?.address?.localizedDisplay ?? '')),
        ]),
      );

  Widget _map() {
    final lat = double.tryParse(widget.event.venue?.latitude ?? '');
    final lng = double.tryParse(widget.event.venue?.longitude ?? '');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Address', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (lat != null && lng != null)
          TextButton(
              onPressed: () => context.push('/event/${widget.event.id}/map',
                  extra: widget.event),
              child: const Text('View on Map')),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 180,
          child: lat == null || lng == null
              ? Container(
                  color: AppColors.surfaceMuted,
                  child: const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.map_outlined, size: 42, color: AppColors.purple),
                    SizedBox(height: 8),
                    Text('Map coordinates not provided')
                  ])))
              : FlutterMap(
                  options: MapOptions(
                      initialCenter: LatLng(lat, lng),
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none)),
                  children: [
                    TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'za.co.futuretimes.events'),
                    MarkerLayer(markers: [
                      Marker(
                          point: LatLng(lat, lng),
                          width: 52,
                          height: 52,
                          child: const Icon(Icons.location_on_rounded,
                              size: 48, color: AppColors.purple))
                    ]),
                  ],
                ),
        ),
      ),
    ]);
  }

  Widget _about() {
    final description = widget.event.description?.text.trim() ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('About Event', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Text(
          description.isEmpty
              ? 'More information will be shared by the organizer soon.'
              : description,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.textMuted)),
    ]);
  }

  Widget _tickets() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a ticket',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...widget.event.ticketClasses.where((t) => !t.hidden).map((ticket) {
            final selected = _selectedTicket?.id == ticket.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => _selectedTicket = ticket),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: selected
                          ? AppColors.purple.withValues(alpha: .08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              selected ? AppColors.purple : AppColors.border)),
                  child: Row(children: [
                    Expanded(
                        child: Text(ticket.name,
                            style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700))),
                    Text(ticket.free ? 'Free' : ticket.cost?.display ?? '',
                        style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            );
          }),
        ],
      );

  Widget _bottomBar() {
    final ticket = _selectedTicket;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.viewPaddingOf(context).bottom + 12),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Expanded(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Price',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(ticket == null ? 'Unavailable' : _price,
                    style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ]),
        ),
        SizedBox(
          width: 170,
          child: FilledButton(
            onPressed: ticket == null ? null : _book,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.pink,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: Text(ticket == null ? 'No tickets' : 'Book Now'),
          ),
        ),
      ]),
    );
  }

  void _book() {
    final ticket = _selectedTicket;
    if (ticket == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${ticket.name} selected. Secure Future Times checkout is not yet available in this build.'),
    ));
  }

  String get _price {
    final ticket = _selectedTicket;
    if (ticket == null) return widget.event.isFree ? 'Free' : 'View tickets';
    return ticket.free ? 'Free' : ticket.cost?.display ?? 'View tickets';
  }
}

class _Fact extends StatelessWidget {
  const _Fact(
      {required this.icon,
      required this.title,
      required this.line1,
      required this.line2});
  final IconData icon;
  final String title;
  final String line1;
  final String line2;
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.purple)),
        const SizedBox(height: 10),
        Text(title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.text, fontWeight: FontWeight.w700)),
        if (line1.isNotEmpty)
          Text(line1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        if (line2.isNotEmpty)
          Text(line2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]);
}

String _category(String value) => value
    .replaceAll(RegExp(r'[_-]+'), ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
