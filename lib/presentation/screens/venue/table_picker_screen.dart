import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/venue_table.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/venue_commerce_repository.dart';
import '../../../services/payments/payment_gateway.dart';

class TablePickerScreen extends StatelessWidget {
  const TablePickerScreen({
    super.key,
    required this.eventId,
    required this.venueRepository,
    required this.paymentRepository,
  });

  final String eventId;
  final VenueCommerceRepository venueRepository;
  final PaymentRepository paymentRepository;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Reserve a table')),
        body: StreamBuilder<List<VenueTable>>(
          stream: venueRepository.watchAvailableTables(eventId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: FilledButton(
                  onPressed: () => (context as Element).markNeedsBuild(),
                  child: const Text('Retry'),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final tables = snapshot.data!;
            if (tables.isEmpty) {
              return const Center(child: Text('No tables available'));
            }
            final grouped = <String, List<VenueTable>>{};
            for (final table in tables) {
              grouped.putIfAbsent(table.zone ?? 'General', () => []).add(table);
            }
            return RefreshIndicator(
              onRefresh: () async {
                await venueRepository.getAvailableTables(eventId);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    ...entry.value.map((table) => _TableCard(
                          table: table,
                          onTap: () => _showReservationSheet(context, table),
                        )),
                  ],
                ],
              ),
            );
          },
        ),
      );

  Future<void> _showReservationSheet(
      BuildContext context, VenueTable table) async {
    var partySize = 1;
    var processing = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(table.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              Text(
                  '${table.zone ?? 'General'} · capacity ${table.capacity} · ${table.currency} ${table.price.toStringAsFixed(2)}'),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                      child: Text('Party size',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  IconButton(
                    onPressed: partySize > 1
                        ? () => setState(() => partySize--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$partySize',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(
                    onPressed: partySize < table.capacity
                        ? () => setState(() => partySize++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Total: ${table.currency} ${table.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: processing
                      ? null
                      : () async {
                          setState(() => processing = true);
                          try {
                            final userId = paymentRepository
                                .clientUserId; // resolved by repository auth
                            final payment =
                                await paymentRepository.initiateCharge(
                              userId: userId,
                              amount: table.price,
                              currency: table.currency,
                              purpose: PaymentPurpose.table,
                              gatewayId: 'manual',
                              relatedEntityId: table.id,
                            );
                            final reservationId =
                                await venueRepository.reserveTable(
                              tableId: table.id,
                              partySize: partySize,
                              paymentTransactionId: payment.id,
                            );
                            if (!context.mounted) return;
                            Navigator.pop(sheetContext);
                            final viewWallet = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Table reserved'),
                                content: const Text(
                                    'Your reservation is ready in Wallet.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Done'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('View in wallet'),
                                  ),
                                ],
                              ),
                            );
                            if (viewWallet == true && context.mounted) {
                              context.go('/wallet');
                            }
                            debugPrint('Reservation created: $reservationId');
                          } catch (error) {
                            if (!context.mounted) return;
                            setState(() => processing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Could not reserve table: $error')),
                            );
                          }
                        },
                  child: processing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reserve and pay'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table, required this.onTap});

  final VenueTable table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = table.status == 'available';
    return Opacity(
      opacity: available ? 1 : .5,
      child: Card(
        child: ListTile(
          enabled: available,
          onTap: available ? onTap : null,
          leading:
              const CircleAvatar(child: Icon(Icons.table_restaurant_outlined)),
          title: Text(table.name),
          subtitle: Text(
              '${table.capacity} seats · ${table.currency} ${table.price.toStringAsFixed(2)}'),
          trailing: Chip(label: Text(table.status)),
        ),
      ),
    );
  }
}
