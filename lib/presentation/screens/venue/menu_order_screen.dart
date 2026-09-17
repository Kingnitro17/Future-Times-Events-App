import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/menu_item.dart';
import '../../../data/models/payment_transaction.dart';
import '../../../data/models/table_reservation.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/venue_commerce_repository.dart';
import '../../../services/payments/payment_exception.dart';
import '../../../services/payments/payment_gateway.dart';
import '../../widgets/event_network_image.dart';

/// User-facing menu ordering for one event.
///
/// Cart state lives in this screen only. The order is charged through
/// [PaymentRepository] (never a gateway directly) and then recorded by
/// [VenueCommerceRepository.placeOrder], matching TablePickerScreen.
class MenuOrderScreen extends StatefulWidget {
  const MenuOrderScreen({
    super.key,
    required this.eventId,
    required this.venueRepository,
    required this.paymentRepository,
  });

  final String eventId;
  final VenueCommerceRepository venueRepository;
  final PaymentRepository paymentRepository;

  @override
  State<MenuOrderScreen> createState() => _MenuOrderScreenState();
}

class _MenuOrderScreenState extends State<MenuOrderScreen> {
  /// Reservation states that must never be offered as an order table.
  static const _inactiveReservations = {
    'cancelled',
    'canceled',
    'expired',
    'refunded',
    'failed',
    'no_show',
  };

  late Future<void> _loadFuture;
  List<MenuItem> _menu = const [];
  List<TableReservation> _reservations = const [];
  final Map<String, int> _cart = <String, int>{};
  String? _category;
  String? _tableReservationId;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.venueRepository.getEventMenu(widget.eventId),
      widget.venueRepository.getMyReservations(limit: 20),
    ]);
    if (!mounted) return;
    setState(() {
      _menu = results[0] as List<MenuItem>;
      _reservations = (results[1] as List<TableReservation>)
          .where((reservation) =>
              reservation.eventId == widget.eventId &&
              !_inactiveReservations.contains(reservation.status.toLowerCase()))
          .toList(growable: false);
      if (_category != null && !_categories.contains(_category)) {
        _category = null;
      }
    });
  }

  void _reload() => setState(() => _loadFuture = _load());

  List<String> get _categories {
    final values = <String>{
      for (final item in _menu)
        if ((item.category ?? '').trim().isNotEmpty) item.category!.trim(),
    }.toList()
      ..sort();
    return values;
  }

  List<MenuItem> get _visibleMenu => _category == null
      ? _menu
      : _menu.where((item) => item.category == _category).toList();

  String get _currency {
    for (final item in _menu) {
      if (item.currency.trim().isNotEmpty) return item.currency.trim();
    }
    return 'USD';
  }

  int get _cartCount =>
      _cart.values.fold(0, (sum, quantity) => sum + quantity);

  double get _cartTotal {
    var total = 0.0;
    for (final entry in _cart.entries) {
      total += (_itemById(entry.key)?.price ?? 0) * entry.value;
    }
    return total;
  }

  List<({MenuItem item, int quantity})> get _cartLines {
    final lines = <({MenuItem item, int quantity})>[];
    for (final entry in _cart.entries) {
      final item = _itemById(entry.key);
      if (item == null) continue;
      lines.add((item: item, quantity: entry.value));
    }
    return lines;
  }

  MenuItem? _itemById(String id) {
    for (final item in _menu) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool _isOrderable(MenuItem item) => item.isAvailable && item.stock > 0;

  void _add(MenuItem item) {
    if (!_isOrderable(item)) return;
    final current = _cart[item.id] ?? 0;
    if (item.stock > 0 && current >= item.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${item.stock} left of ${item.name}.')),
      );
      return;
    }
    setState(() => _cart[item.id] = current + 1);
  }

  void _decrement(String menuItemId) {
    final current = _cart[menuItemId] ?? 0;
    setState(() {
      if (current <= 1) {
        _cart.remove(menuItemId);
      } else {
        _cart[menuItemId] = current - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Order food and drinks')),
        body: FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MenuError(onRetry: _reload);
            }
            if (_menu.isEmpty) return const _MenuEmpty();
            return Column(
              children: [
                if (_categories.isNotEmpty) _categoryBar(),
                Expanded(child: _grid()),
              ],
            );
          },
        ),
        bottomNavigationBar: _menu.isEmpty ? null : _bottomBar(),
      );

  Widget _categoryBar() => SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _category == null,
              onSelected: (_) => setState(() => _category = null),
            ),
            ..._categories.map((category) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                )),
          ],
        ),
      );

  Widget _grid() {
    final items = _visibleMenu;
    if (items.isEmpty) {
      return const Center(
        child: Text('Nothing in this category yet.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    final columns = ResponsiveUtils.isCompact(context)
        ? 2
        : ResponsiveUtils.isMedium(context)
            ? 3
            : 4;
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 262,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _MenuCard(
            item: item,
            currency: _currency,
            quantity: _cart[item.id] ?? 0,
            onAdd: () => _add(item),
            onRemove: () => _decrement(item.id),
          );
        },
      ),
    );
  }

  Widget _bottomBar() => Container(
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
                Text(
                    '$_cartCount ${_cartCount == 1 ? 'item' : 'items'} in cart',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(_money(_currency, _cartTotal),
                    style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          SizedBox(
            width: 170,
            child: FilledButton(
              onPressed: _cart.isEmpty ? null : _openCartSheet,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.pink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              child: const Text('Review order'),
            ),
          ),
        ]),
      );

  Future<void> _openCartSheet() async {
    if (_cart.isEmpty) return;
    final noteController = TextEditingController();
    var selectedReservationId = _tableReservationId;
    var processing = false;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) {
            final total = _cartTotal;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your order',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                        '$_cartCount ${_cartCount == 1 ? 'item' : 'items'} · '
                        '${_money(_currency, total)}',
                        style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 14),
                    ..._cartLines.map((line) => _CartLine(
                          name: line.item.name,
                          unitPrice: _money(_currency, line.item.price),
                          quantity: line.quantity,
                          onIncrement: processing
                              ? null
                              : () => setSheetState(() {
                                    _cart[line.item.id] = line.quantity + 1;
                                  }),
                          onDecrement: processing
                              ? null
                              : () => setSheetState(() {
                                    if (line.quantity <= 1) {
                                      _cart.remove(line.item.id);
                                    } else {
                                      _cart[line.item.id] = line.quantity - 1;
                                    }
                                  }),
                        )),
                    const Divider(height: 28),
                    if (_reservations.isNotEmpty) ...[
                      const Text('Deliver to a table',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Table (optional)',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: selectedReservationId,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('No table'),
                              ),
                              ..._reservations.map(
                                (reservation) => DropdownMenuItem<String?>(
                                  value: reservation.id,
                                  child: Text(
                                    '${reservation.tableName ?? 'Table'} · '
                                    '${reservation.partySize} '
                                    '${reservation.partySize == 1 ? 'guest' : 'guests'}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: processing
                                ? null
                                : (value) => setSheetState(
                                    () => selectedReservationId = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      enabled: !processing,
                      decoration: const InputDecoration(
                        labelText: 'Note for the kitchen (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(_money(_currency, total),
                                style: const TextStyle(
                                    color: AppColors.purple,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: FilledButton(
                          onPressed: processing
                              ? null
                              : () async {
                                  setSheetState(() => processing = true);
                                  String? failure;
                                  final orderId = await _submitOrder(
                                    total: total,
                                    tableReservationId: selectedReservationId,
                                    note: noteController.text.trim(),
                                    failureMessage: (message) =>
                                        failure = message,
                                  );
                                  if (orderId == null) {
                                    if (!sheetContext.mounted) return;
                                    setSheetState(() => processing = false);
                                    ScaffoldMessenger.of(sheetContext)
                                        .showSnackBar(SnackBar(
                                      content: Text(failure ??
                                          'Could not place your order.'),
                                      duration: const Duration(seconds: 6),
                                    ));
                                    return;
                                  }
                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                  setState(() => _cart.clear());
                                  await _showOrderPlaced(orderId);
                                },
                          child: processing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Place order'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      noteController.dispose();
    }
  }

  /// Charges through [PaymentRepository], then records the order. Returns the
  /// new order id on success, or null on failure - in which case any completed
  /// charge has been reversed and [failureMessage] holds the user-facing text.
  Future<String?> _submitOrder({
    required double total,
    required String? tableReservationId,
    required String note,
    required void Function(String message) failureMessage,
  }) async {
    // Snapshot so the charged amount and the ordered items can never diverge.
    final lines = _cartLines;
    final currency = _currency;
    PaymentTransaction? charge;
    try {
      final userId = widget.paymentRepository.clientUserId;
      charge = await widget.paymentRepository.initiateCharge(
        userId: userId,
        amount: total,
        currency: currency,
        purpose: PaymentPurpose.order,
        gatewayId: 'manual',
        relatedEntityId: widget.eventId,
      );
      final orderId = await widget.venueRepository.placeOrder(
        eventId: widget.eventId,
        items: [
          for (final line in lines)
            {
              'menu_item_id': line.item.id,
              'item_name': line.item.name,
              'quantity': line.quantity,
              'unit_price': line.item.price,
            },
        ],
        tableReservationId: tableReservationId,
        paymentTransactionId: charge.id,
        note: note.isEmpty ? null : note,
      );
      _tableReservationId = tableReservationId;
      return orderId;
    } catch (error) {
      // Placement (or the charge itself) failed: never leave a completed
      // payment standing against an order that does not exist.
      final reversed = await _reverseCharge(charge, total);
      failureMessage(
          _failureMessage(error, reversed: reversed, charge: charge));
      return null;
    }
  }

  /// Reverses a completed charge after a failed placement. Returns true only
  /// when the reversal really succeeded.
  Future<bool> _reverseCharge(PaymentTransaction? charge, double amount) async {
    if (charge == null || charge.status != PaymentStatus.paid) return false;
    try {
      await widget.paymentRepository.refund(charge.id, amount);
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[order] reversal after failed placement: $error');
      }
      return false;
    }
  }

  /// Reversal status outranks the raw error text: what the user needs to know
  /// first is whether their money came back.
  String _failureMessage(
    Object error, {
    required bool reversed,
    required PaymentTransaction? charge,
  }) {
    if (reversed) {
      return 'Could not place your order. Your payment was reversed.';
    }
    if (charge != null && charge.status == PaymentStatus.paid) {
      return 'Could not place your order, and payment ${charge.id} could not be '
          'reversed automatically. Please contact support.';
    }
    if (error is PaymentException) return error.message;
    if (error is StateError) return error.message.toString();
    return 'Could not place your order. Please try again.';
  }

  Future<void> _showOrderPlaced(String orderId) async {
    if (!mounted) return;
    debugPrint('Venue order created: $orderId');
    final viewWallet = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Order placed'),
        content: const Text(
            'Your order is on its way to the venue. Track it in Wallet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('View in wallet'),
          ),
        ],
      ),
    );
    if (viewWallet == true && mounted) context.go('/wallet');
  }
}

String _money(String currency, double amount) {
  final code = currency.trim().isEmpty ? 'USD' : currency.trim();
  return '$code ${amount.toStringAsFixed(2)}';
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.item,
    required this.currency,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final MenuItem item;
  final String currency;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  bool get _orderable => item.isAvailable && item.stock > 0;

  @override
  Widget build(BuildContext context) {
    final description = item.description?.trim() ?? '';
    return Opacity(
      opacity: _orderable ? 1 : .5,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              width: double.infinity,
              child: EventNetworkImage(
                url: item.imageUrl,
                semanticLabel: '${item.name} photo',
                fallbackIcon: Icons.restaurant_rounded,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800)),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Flexible(
                              child: Text(description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(_money(currency, item.price),
                        style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    if (!_orderable)
                      const Center(
                        child: Text('Sold out',
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      )
                    else if (quantity == 0)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onAdd,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          child: const Text('Add'),
                        ),
                      )
                    else
                      Row(children: [
                        _StepperButton(icon: Icons.remove, onTap: onRemove),
                        Expanded(
                          child: Text('$quantity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w900)),
                        ),
                        _StepperButton(icon: Icons.add, onTap: onAdd),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String name;
  final String unitPrice;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(unitPrice,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          _StepperButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 34,
            child: Text('$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrement),
        ]),
      );
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: enabled ? .1 : .04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled
                ? AppColors.purple
                : AppColors.textMuted.withValues(alpha: .4)),
      ),
    );
  }
}

class _MenuEmpty extends StatelessWidget {
  const _MenuEmpty();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_outlined,
                  size: 68, color: AppColors.purple),
              SizedBox(height: 16),
              Text('No menu yet for this event',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Check back closer to the event.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
}

class _MenuError extends StatelessWidget {
  const _MenuError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load the menu.'),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
