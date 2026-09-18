import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/table_reservation.dart';
import '../../../data/models/venue_order.dart';
import '../../../data/models/venue_table.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../../data/repositories/venue_commerce_repository.dart';

/// Staff fulfillment board for one event: live orders, table seating and QR
/// scanning for venue codes as well as admission tickets.
///
/// Access is limited to the event organizer (or a super admin) by
/// [OrganizerRepository.getEventOwnerView], which rejects every other account.
class VenueFulfillmentScreen extends StatefulWidget {
  const VenueFulfillmentScreen({
    super.key,
    required this.eventId,
    required this.organizerRepository,
    required this.ticketRepository,
    required this.venueRepository,
  });

  final String eventId;
  final OrganizerRepository organizerRepository;
  final TicketRepository ticketRepository;
  final VenueCommerceRepository venueRepository;

  @override
  State<VenueFulfillmentScreen> createState() => _VenueFulfillmentScreenState();
}

class _VenueFulfillmentScreenState extends State<VenueFulfillmentScreen> {
  static const _activeStatuses = {'paid', 'preparing', 'ready'};
  static const _confirmedStatus = 'confirmed';
  static const _usedStatus = 'used';

  late Future<Map<String, dynamic>> _eventFuture;
  StreamSubscription<List<VenueOrder>>? _ordersSubscription;
  StreamSubscription<List<TableReservation>>? _reservationsSubscription;
  StreamSubscription<List<VenueTable>>? _tablesSubscription;

  List<VenueOrder> _orders = const [];
  List<TableReservation> _reservations = const [];
  List<VenueTable> _tables = const [];
  Map<String, String> _guestNames = const <String, String>{};

  /// Row ids with an in-flight write, so a row can show progress and cannot be
  /// double tapped.
  final Set<String> _busy = <String>{};
  Object? _streamError;
  bool _ordersLoaded = false;
  bool _reservationsLoaded = false;
  bool _tablesLoaded = false;
  String _orderFilter = 'active';

  @override
  void initState() {
    super.initState();
    _eventFuture = _loadAuthorizedEvent();
  }

  /// Do not subscribe to staff data until the event-owner guard has passed.
  /// This keeps the screen's data access aligned with its route-level role
  /// guard and also covers an organizer opening another organizer's event.
  Future<Map<String, dynamic>> _loadAuthorizedEvent() async {
    final event =
        await widget.organizerRepository.getEventOwnerView(widget.eventId);
    if (mounted) _subscribe();
    return event;
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _reservationsSubscription?.cancel();
    _tablesSubscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    _ordersSubscription?.cancel();
    _reservationsSubscription?.cancel();
    _tablesSubscription?.cancel();
    _ordersSubscription = widget.venueRepository
        .watchEventOrders(widget.eventId)
        .listen(_onOrders, onError: _onStreamError);
    _reservationsSubscription = widget.venueRepository
        .watchEventReservations(widget.eventId)
        .listen(_onReservations, onError: _onStreamError);
    // watchAvailableTables streams every table for the event, which is what the
    // zone grouping and occupancy labels need.
    _tablesSubscription = widget.venueRepository
        .watchAvailableTables(widget.eventId)
        .listen(_onTables, onError: _onStreamError);
  }

  void _onStreamError(Object error) {
    if (!mounted) return;
    setState(() => _streamError = error);
  }

  void _onOrders(List<VenueOrder> orders) {
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _ordersLoaded = true;
      _streamError = null;
    });
  }

  void _onReservations(List<TableReservation> reservations) {
    if (!mounted) return;
    setState(() {
      _reservations = reservations;
      _reservationsLoaded = true;
      _streamError = null;
    });
    unawaited(_loadGuestNames());
  }

  void _onTables(List<VenueTable> tables) {
    if (!mounted) return;
    setState(() {
      _tables = tables;
      _tablesLoaded = true;
      _streamError = null;
    });
  }

  /// Reservations only carry a user id, so guest names come from the same
  /// profiles lookup the attendee list uses.
  Future<void> _loadGuestNames() async {
    final ids = _reservations.map((reservation) => reservation.userId).toSet();
    if (ids.isEmpty) return;
    final names = await widget.venueRepository.getGuestNames(ids);
    if (!mounted || names.isEmpty) return;
    setState(() => _guestNames = {..._guestNames, ...names});
  }

  Future<void> _refresh() async {
    _subscribe();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  bool _isBusy(String id) => _busy.contains(id);

  List<VenueOrder> get _visibleOrders {
    final rows =
        _orders.where((order) => _matchesOrderFilter(order.status)).toList();
    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  bool _matchesOrderFilter(String status) {
    final value = status.toLowerCase();
    switch (_orderFilter) {
      case 'delivered':
        return value == 'delivered';
      case 'all':
        return true;
      default:
        return _activeStatuses.contains(value);
    }
  }

  VenueTable? _tableById(String? tableId) {
    if (tableId == null || tableId.isEmpty) return null;
    for (final table in _tables) {
      if (table.id == tableId) return table;
    }
    return null;
  }

  String _zoneForTable(String? tableId) {
    final zone = _tableById(tableId)?.zone?.trim() ?? '';
    return zone.isEmpty ? 'General' : zone;
  }

  /// Orders only carry a reservation id, so the table name comes from the
  /// reservation list.
  String? _tableNameForOrder(VenueOrder order) {
    final reservationId = order.tableReservationId;
    if (reservationId == null || reservationId.isEmpty) return null;
    for (final reservation in _reservations) {
      if (reservation.id == reservationId) return reservation.tableName;
    }
    return null;
  }

  String _guestName(TableReservation reservation) {
    final name = _guestNames[reservation.userId]?.trim() ?? '';
    return name.isEmpty ? 'Guest' : name;
  }

  List<TableReservation> get _awaitingSeating {
    final rows = _reservations
        .where((reservation) =>
            reservation.status.toLowerCase() == _confirmedStatus)
        .toList();
    rows.sort((a, b) => a.reservedAt.compareTo(b.reservedAt));
    return rows;
  }

  /// Occupancy is driven by the table, because seating a party also flips the
  /// reservation to 'used' (which removes it from the awaiting list).
  List<({VenueTable table, TableReservation? reservation})>
      get _occupiedTables {
    final rows = _tables
        .where((table) => table.status.toLowerCase() == 'occupied')
        .toList();
    rows.sort((a, b) => a.name.compareTo(b.name));
    return [
      for (final table in rows)
        (table: table, reservation: _latestSeated(table.id)),
    ];
  }

  TableReservation? _latestSeated(String tableId) {
    TableReservation? latest;
    for (final reservation in _reservations) {
      if (reservation.tableId != tableId) continue;
      if (reservation.status.toLowerCase() != _usedStatus) continue;
      if (latest == null || reservation.reservedAt.isAfter(latest.reservedAt)) {
        latest = reservation;
      }
    }
    return latest;
  }

  List<Widget> _groupByZone<T>(
    List<T> rows,
    String Function(T row) zoneOf,
    Widget Function(T row) builder,
  ) {
    final grouped = <String, List<T>>{};
    for (final row in rows) {
      grouped.putIfAbsent(zoneOf(row), () => <T>[]).add(row);
    }
    final zones = grouped.keys.toList()..sort();
    return [
      for (final zone in zones) ...[
        _ZoneHeader(zone),
        for (final row in grouped[zone]!) builder(row),
      ],
    ];
  }

  Future<void> _advanceOrder(VenueOrder order, String nextStatus) async {
    if (_isBusy(order.id)) return;
    setState(() => _busy.add(order.id));
    try {
      await widget.venueRepository.updateOrderStatus(order.id, nextStatus);
      _notify('Order ${_shortId(order.id)} marked $nextStatus.');
    } catch (error) {
      _notify('Could not update the order: $error');
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _seatGuests(TableReservation reservation) async {
    if (_isBusy(reservation.id)) return;
    final table = reservation.tableName ?? 'this table';
    final confirmed = await _confirm(
      title: 'Seat guests at $table?',
      message: '${reservation.partySize} '
          '${reservation.partySize == 1 ? 'guest' : 'guests'} - '
          '${_guestName(reservation)}',
      confirmLabel: 'Seat guests',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(reservation.id));
    try {
      await widget.venueRepository.seatReservation(
        reservationId: reservation.id,
        tableId: reservation.tableId,
      );
      _notify('$table is now occupied.');
    } catch (error) {
      _notify('Could not seat guests: $error');
    } finally {
      if (mounted) setState(() => _busy.remove(reservation.id));
    }
  }

  Future<void> _freeTable(VenueTable table) async {
    if (_isBusy(table.id)) return;
    final confirmed = await _confirm(
      title: 'Free ${table.name}?',
      message: 'The table becomes available for the next party. The guest '
          'history is kept.',
      confirmLabel: 'Free table',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(table.id));
    try {
      await widget.venueRepository.freeTable(table.id);
      _notify('${table.name} is available.');
    } catch (error) {
      _notify('Could not free the table: $error');
    } finally {
      if (mounted) setState(() => _busy.remove(table.id));
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Fulfillment')),
              body: const _AccessDenied(),
            );
          }
          final event = snapshot.data!;
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Fulfillment'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Orders'),
                    Tab(text: 'Tables'),
                    Tab(text: 'Scan'),
                  ],
                ),
              ),
              body: Column(
                children: [
                  _eventHeader(event),
                  if (_streamError != null) _errorBanner(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ordersTab(),
                        _tablesTab(),
                        _ScanTab(
                          eventId: widget.eventId,
                          ticketRepository: widget.ticketRepository,
                          venueRepository: widget.venueRepository,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _eventHeader(Map<String, dynamic> event) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
        child: Row(
          children: [
            const Icon(Icons.room_service_outlined, color: AppColors.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event['id'] == null ? '' : (event['title']?.toString() ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            Text('${_awaitingSeating.length} waiting',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );

  Widget _errorBanner() => Container(
        width: double.infinity,
        color: AppColors.error.withValues(alpha: .08),
        padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Live updates are interrupted.',
                  style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
            TextButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      );

  Widget _ordersTab() {
    if (!_ordersLoaded && _streamError == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final orders = _visibleOrders;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Row(
            children: [
              for (final entry in const [
                ('active', 'Active'),
                ('delivered', 'Delivered'),
                ('all', 'All'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: _orderFilter == entry.$1,
                    onSelected: (_) => setState(() => _orderFilter = entry.$1),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const _EmptyState('No orders match this filter.')
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _OrderCard(
                        order: order,
                        tableName: _tableNameForOrder(order),
                        busy: _isBusy(order.id),
                        onAdvance: (status) => _advanceOrder(order, status),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tablesTab() {
    if (!_reservationsLoaded && !_tablesLoaded && _streamError == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final awaiting = _awaitingSeating;
    final occupied = _occupiedTables;
    if (awaiting.isEmpty && occupied.isEmpty) {
      return const _EmptyState('No reservations or seated tables yet.');
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const _SectionHeader('Awaiting seating'),
          if (awaiting.isEmpty)
            const _MutedLine('Nothing is awaiting seating.')
          else
            ..._groupByZone(
              awaiting,
              (reservation) => _zoneForTable(reservation.tableId),
              (reservation) => _ReservationTile(
                reservation: reservation,
                guestName: _guestName(reservation),
                busy: _isBusy(reservation.id),
                onSeat: () => _seatGuests(reservation),
              ),
            ),
          const SizedBox(height: 22),
          const _SectionHeader('Occupied tables'),
          if (occupied.isEmpty)
            const _MutedLine('No tables are currently occupied.')
          else
            ..._groupByZone(
              occupied,
              (entry) => _zoneForTable(entry.table.id),
              (entry) => _OccupiedTile(
                table: entry.table,
                reservation: entry.reservation,
                guestName: entry.reservation == null
                    ? null
                    : _guestName(entry.reservation!),
                busy: _isBusy(entry.table.id),
                onFree: () => _freeTable(entry.table),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.tableName,
    required this.busy,
    required this.onAdvance,
  });

  final VenueOrder order;
  final String? tableName;
  final bool busy;
  final ValueChanged<String> onAdvance;

  @override
  Widget build(BuildContext context) {
    final action = _nextOrderAction(order.status);
    final color = _orderStatusColor(order.status);
    final note = (order.note ?? '').trim();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${_shortId(order.id)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                _Pill(label: order.status.replaceAll('_', ' '), color: color),
                const Spacer(),
                Text(_elapsed(order.createdAt),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.table_restaurant_outlined,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(tableName ?? 'No table',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(width: 14),
                const Icon(Icons.payments_outlined,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('${order.currency} ${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('${item.quantity} x ${item.itemName}',
                    style: const TextStyle(fontSize: 13)),
              ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: $note',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ],
            if (action != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : () => onAdvance(action.status),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(action.label),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({
    required this.reservation,
    required this.guestName,
    required this.busy,
    required this.onSeat,
  });

  final TableReservation reservation;
  final String guestName;
  final bool busy;
  final VoidCallback onSeat;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reservation.tableName ?? 'Table',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(guestName,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${reservation.partySize} '
                      '${reservation.partySize == 1 ? 'guest' : 'guests'} · '
                      '${DateFormat.jm().format(reservation.reservedAt.toLocal())}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: busy ? null : onSeat,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Seat guests'),
              ),
            ],
          ),
        ),
      );
}

class _OccupiedTile extends StatelessWidget {
  const _OccupiedTile({
    required this.table,
    required this.reservation,
    required this.guestName,
    required this.busy,
    required this.onFree,
  });

  final VenueTable table;
  final TableReservation? reservation;
  final String? guestName;
  final bool busy;
  final VoidCallback onFree;

  @override
  Widget build(BuildContext context) {
    final seated = reservation;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(table.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(guestName ?? 'Guests seated',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    seated == null
                        ? 'Seated'
                        : '${seated.partySize} '
                            '${seated.partySize == 1 ? 'guest' : 'guests'} · '
                            '${DateFormat.jm().format(seated.reservedAt.toLocal())}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: busy ? null : onFree,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Free table'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Camera tab. Mirrors the scanner in scan_ticket_screen.dart, but routes the
/// payload by prefix: venue table codes, venue order codes, then tickets.
class _ScanTab extends StatefulWidget {
  const _ScanTab({
    required this.eventId,
    required this.ticketRepository,
    required this.venueRepository,
  });

  final String eventId;
  final TicketRepository ticketRepository;
  final VenueCommerceRepository venueRepository;

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  static const _tablePrefix = 'FTE-TBL';
  static const _orderPrefix = 'FTE-ORD';

  final MobileScannerController _controller = MobileScannerController();
  final Map<String, DateTime> _recentScans = {};
  Timer? _resultTimer;
  bool _processing = false;
  _ScanOutcome? _outcome;
  int _handledCount = 0;

  @override
  void dispose() {
    _resultTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_processing || _outcome != null) return;
    final payload = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (payload == null) return;

    final now = DateTime.now();
    final previous = _recentScans[payload];
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 3)) {
      return;
    }
    _recentScans[payload] = now;
    _recentScans.removeWhere((_, timestamp) =>
        now.difference(timestamp) > const Duration(seconds: 3));

    await _run(payload);
  }

  Future<void> _manualEntry() async {
    final controller = TextEditingController();
    final payload = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manual entry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Table, order or ticket code',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Look up')),
        ],
      ),
    );
    controller.dispose();
    final clean = payload?.trim() ?? '';
    if (clean.isNotEmpty) await _run(clean);
  }

  /// Stops the camera while a code runs, then resumes once the result card has
  /// been shown.
  Future<void> _run(String payload) async {
    setState(() => _processing = true);
    await _controller.stop();
    try {
      final upper = payload.toUpperCase();
      if (upper.startsWith(_tablePrefix)) {
        await _handleTable(payload);
      } else if (upper.startsWith(_orderPrefix)) {
        await _handleOrder(payload);
      } else if (upper.startsWith('FTE')) {
        await _handleTicket(payload);
      } else {
        _show(_ScanOutcome.failure('This is not a Future Times Events code.'));
      }
    } catch (error) {
      if (mounted) _show(_ScanOutcome.failure('Scan failed: $error'));
    }
  }

  Future<void> _handleTicket(String payload) async {
    final result = await widget.ticketRepository.validateAndCheckInTicket(
      qrPayload: payload,
      gate: 'Venue',
    );
    if (!mounted) return;
    final valid = result['valid'] == true;
    final alreadyCheckedIn = result['already_checked_in'] == true;
    final message =
        result['message']?.toString() ?? 'Ticket could not be validated.';
    final attendee = result['attendee_name']?.toString().trim() ?? '';
    final detail = attendee.isEmpty ? message : '$attendee\n$message';
    if (valid) _handledCount++;
    if (alreadyCheckedIn) {
      _show(_ScanOutcome.warning('Already checked in', detail));
      return;
    }
    if (valid) {
      _show(_ScanOutcome.success('Valid ticket', detail));
      return;
    }
    _show(_ScanOutcome.failure(message));
  }

  Future<void> _handleTable(String payload) async {
    final reservation =
        await widget.venueRepository.getReservationByQr(payload);
    if (!mounted) return;
    if (reservation == null) {
      _show(_ScanOutcome.failure('No reservation matches this table code.'));
      return;
    }
    if (reservation.eventId != widget.eventId) {
      _show(_ScanOutcome.failure('That reservation belongs to another event.'));
      return;
    }
    if (reservation.status.toLowerCase() != 'confirmed') {
      _show(_ScanOutcome.warning(
        'Reservation unavailable',
        'This reservation is ${reservation.status.replaceAll('_', ' ')}.',
      ));
      return;
    }
    final table = reservation.tableName ?? 'this table';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Seat guests at $table?'),
        content: Text('${reservation.status.replaceAll('_', ' ')} · '
            '${reservation.partySize} '
            '${reservation.partySize == 1 ? 'guest' : 'guests'}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Seat guests')),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      _show(_ScanOutcome.warning('Not seated', '$table was left unchanged.'));
      return;
    }
    try {
      await widget.venueRepository.seatReservation(
        reservationId: reservation.id,
        tableId: reservation.tableId,
      );
      if (!mounted) return;
      _handledCount++;
      _show(_ScanOutcome.success('Guests seated', '$table is now occupied.'));
    } catch (error) {
      if (!mounted) return;
      _show(_ScanOutcome.failure('Could not seat guests: $error'));
    }
  }

  Future<void> _handleOrder(String payload) async {
    final order = await widget.venueRepository.getOrderByQr(payload);
    if (!mounted) return;
    if (order == null) {
      _show(_ScanOutcome.failure('No order matches this order code.'));
      return;
    }
    if (order.eventId != widget.eventId) {
      _show(_ScanOutcome.failure('That order belongs to another event.'));
      return;
    }
    final action = _nextOrderAction(order.status);
    final note = (order.note ?? '').trim();
    final advance = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Order #${_shortId(order.id)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                      color: _orderStatusColor(order.status),
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              for (final item in order.items)
                Text('${item.quantity} x ${item.itemName}'),
              const SizedBox(height: 10),
              Text('Total ${order.currency} ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: $note'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Close')),
          if (action != null)
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action.label)),
        ],
      ),
    );
    if (!mounted) return;
    if (advance != true || action == null) {
      _show(_ScanOutcome.warning(
          'Order #${_shortId(order.id)}', order.status.replaceAll('_', ' ')));
      return;
    }
    try {
      await widget.venueRepository.updateOrderStatus(order.id, action.status);
      if (!mounted) return;
      _handledCount++;
      _show(_ScanOutcome.success(
          'Order ${action.status}', 'Order #${_shortId(order.id)} updated.'));
    } catch (error) {
      if (!mounted) return;
      _show(_ScanOutcome.failure('Could not update the order: $error'));
    }
  }

  void _show(_ScanOutcome outcome) {
    if (!mounted) return;
    setState(() {
      _processing = false;
      _outcome = outcome;
    });
    if (outcome.kind == _ScanKind.failure) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    _resultTimer = Timer(const Duration(milliseconds: 2500), _resume);
  }

  Future<void> _resume() async {
    if (!mounted) return;
    setState(() => _outcome = null);
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleBarcode),
          IgnorePointer(child: CustomPaint(painter: _ScannerOverlayPainter())),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                if (_processing)
                  const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 18),
                Text('Handled: $_handledCount',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Tickets · table codes · order codes',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: OutlinedButton.icon(
                    onPressed:
                        _processing || _outcome != null ? null : _manualEntry,
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text('Manual entry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_outcome != null) _resultOverlay(),
        ],
      );

  Widget _resultOverlay() {
    final outcome = _outcome!;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(outcome.icon, color: outcome.color, size: 60),
              const SizedBox(height: 12),
              Text(outcome.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: outcome.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(outcome.message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderAction {
  const _OrderAction(this.status, this.label);

  final String status;
  final String label;
}

_OrderAction? _nextOrderAction(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return const _OrderAction('preparing', 'Start preparing');
    case 'preparing':
      return const _OrderAction('ready', 'Mark ready');
    case 'ready':
      return const _OrderAction('delivered', 'Mark delivered');
  }
  return null;
}

Color _orderStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return AppColors.purple;
    case 'preparing':
      return Colors.orange.shade800;
    case 'ready':
      return AppColors.success;
    case 'delivered':
      return AppColors.textMuted;
    default:
      return AppColors.textSecondary;
  }
}

String _shortId(String value) =>
    value.length <= 8 ? value : value.substring(0, 8);

String _elapsed(DateTime createdAt) {
  final elapsed = DateTime.now().difference(createdAt);
  if (elapsed.isNegative || elapsed.inMinutes == 0) return 'just now';
  if (elapsed.inHours == 0) return '${elapsed.inMinutes}m ago';
  if (elapsed.inDays == 0) return '${elapsed.inHours}h ago';
  return '${elapsed.inDays}d ago';
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
}

class _ZoneHeader extends StatelessWidget {
  const _ZoneHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900));
}

class _MutedLine extends StatelessWidget {
  const _MutedLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined,
                  color: AppColors.textMuted, size: 38),
              const SizedBox(height: 10),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: AppColors.textMuted, size: 38),
              SizedBox(height: 10),
              Text(
                'This fulfillment board is only available to the event organizer or a super admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
}

enum _ScanKind { success, warning, failure }

class _ScanOutcome {
  const _ScanOutcome(this.kind, this.title, this.message);

  factory _ScanOutcome.success(String title, String message) =>
      _ScanOutcome(_ScanKind.success, title, message);
  factory _ScanOutcome.warning(String title, String message) =>
      _ScanOutcome(_ScanKind.warning, title, message);
  factory _ScanOutcome.failure(String message) =>
      _ScanOutcome(_ScanKind.failure, 'Unable to process', message);

  final _ScanKind kind;
  final String title;
  final String message;

  Color get color => switch (kind) {
        _ScanKind.success => AppColors.success,
        _ScanKind.warning => Colors.amber.shade800,
        _ScanKind.failure => AppColors.error,
      };

  IconData get icon => switch (kind) {
        _ScanKind.success => Icons.check_circle_rounded,
        _ScanKind.warning => Icons.warning_amber_rounded,
        _ScanKind.failure => Icons.cancel_rounded,
      };
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frameSize = size.shortestSide * .68;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .43),
      width: frameSize,
      height: frameSize,
    );
    final overlay = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, overlay, cutout),
      Paint()..color = Colors.black.withValues(alpha: .58),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
