import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/menu_item.dart';
import '../../../data/models/venue_table.dart';
import '../../../data/repositories/venue_commerce_repository.dart';

class VenueSetupScreen extends StatefulWidget {
  const VenueSetupScreen({
    super.key,
    required this.eventId,
    required this.venueRepository,
  });

  final String eventId;
  final VenueCommerceRepository venueRepository;

  @override
  State<VenueSetupScreen> createState() => _VenueSetupScreenState();
}

class _VenueSetupScreenState extends State<VenueSetupScreen> {
  late Future<void> _loadFuture;
  List<VenueTable> _tables = const [];
  List<MenuItem> _menu = const [];
  String? _zone;
  String? _category;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.venueRepository.getEventTables(widget.eventId),
      widget.venueRepository.getEventMenu(widget.eventId),
    ]);
    if (!mounted) return;
    setState(() {
      _tables = results[0] as List<VenueTable>;
      _menu = results[1] as List<MenuItem>;
    });
  }

  void _reload() => setState(() => _loadFuture = _load());

  Future<void> _deleteTable(VenueTable table) async {
    if (!await _confirm('Delete ${table.name}?')) return;
    await widget.venueRepository.deleteTable(table.id);
    _reload();
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    if (!await _confirm('Delete ${item.name}?')) return;
    await widget.venueRepository.deleteMenuItem(item.id);
    _reload();
  }

  Future<bool> _confirm(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Venue Setup'),
            bottom: const TabBar(tabs: [
              Tab(text: 'Tables'),
              Tab(text: 'Menu'),
            ]),
          ),
          body: FutureBuilder<void>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: FilledButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                );
              }
              return TabBarView(children: [_tablesTab(), _menuTab()]);
            },
          ),
        ),
      );

  Widget _tablesTab() {
    final zones = _tables
        .map((table) => table.zone)
        .whereType<String>()
        .where((zone) => zone.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final tables = _zone == null
        ? _tables
        : _tables.where((t) => t.zone == _zone).toList();
    return _tabScaffold(
      filter: zones.isEmpty
          ? null
          : _filterChips(zones, _zone, (value) {
              setState(() => _zone = value);
            }),
      empty: 'No tables yet. Add your first table.',
      children: tables
          .map((table) => Dismissible(
                key: ValueKey(table.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  await _deleteTable(table);
                  return false;
                },
                background: _deleteBackground(),
                child: Card(
                  child: ListTile(
                    onTap: () async {
                      await context.push(
                        '/organizer/events/${widget.eventId}/venue/table',
                        extra: table,
                      );
                      _reload();
                    },
                    leading: const CircleAvatar(
                        child: Icon(Icons.table_restaurant_outlined)),
                    title: Text(table.name),
                    subtitle: Text(
                        '${table.zone ?? 'No zone'} · ${table.capacity} seats · ${table.currency} ${table.price.toStringAsFixed(2)}'),
                    trailing: _statusChip(table.status),
                  ),
                ),
              ))
          .toList(),
      onAdd: () async {
        await context.push('/organizer/events/${widget.eventId}/venue/table');
        _reload();
      },
      addLabel: 'Add table',
    );
  }

  Widget _menuTab() {
    final categories = _menu
        .map((item) => item.category)
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final menu = _category == null
        ? _menu
        : _menu.where((item) => item.category == _category).toList();
    final grouped = <String, List<MenuItem>>{};
    for (final item in menu) {
      grouped.putIfAbsent(item.category ?? 'Uncategorized', () => []).add(item);
    }
    final menuChildren = <Widget>[];
    for (final entry in grouped.entries) {
      menuChildren.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
        child: Text(entry.key,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      ));
      menuChildren.addAll(entry.value.map((item) => Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _deleteMenuItem(item);
              return false;
            },
            background: _deleteBackground(),
            child: Card(
              child: ListTile(
                onTap: () async {
                  await context.push(
                    '/organizer/events/${widget.eventId}/venue/menu',
                    extra: item,
                  );
                  _reload();
                },
                leading:
                    const CircleAvatar(child: Icon(Icons.restaurant_outlined)),
                title: Text(item.name),
                subtitle:
                    Text('${item.currency} ${item.price.toStringAsFixed(2)}'),
                trailing: Icon(
                  item.isAvailable
                      ? Icons.check_circle_outline
                      : Icons.remove_circle_outline,
                  color: item.isAvailable
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
              ),
            ),
          )));
    }
    return _tabScaffold(
      filter: categories.isEmpty
          ? null
          : _filterChips(categories, _category, (value) {
              setState(() => _category = value);
            }),
      empty: 'No menu items yet. Add your first item.',
      children: menuChildren,
      onAdd: () async {
        await context.push('/organizer/events/${widget.eventId}/venue/menu');
        _reload();
      },
      addLabel: 'Add item',
    );
  }

  Widget _filterChips(
    List<String> values,
    String? selected,
    ValueChanged<String?> onChanged,
  ) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
            ...values.map((value) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(value),
                    selected: selected == value,
                    onSelected: (_) => onChanged(value),
                  ),
                )),
          ],
        ),
      );

  Widget _tabScaffold({
    required Widget? filter,
    required String empty,
    required List<Widget> children,
    required VoidCallback onAdd,
    required String addLabel,
  }) =>
      Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
              children: [
                if (filter != null) filter,
                if (children.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(child: Text(empty)),
                  )
                else
                  ...children,
              ],
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton.extended(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(addLabel),
            ),
          ),
        ],
      );

  Widget _deleteBackground() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      );

  Widget _statusChip(String status) => Chip(
        label: Text(status),
        visualDensity: VisualDensity.compact,
      );
}
