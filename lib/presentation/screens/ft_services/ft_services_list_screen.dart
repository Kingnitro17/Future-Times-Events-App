import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/ft_service.dart';
import '../../../data/repositories/ft_services_repository.dart';
import '../../widgets/ft_services_section.dart';

class FtServicesListScreen extends StatefulWidget {
  FtServicesListScreen({super.key, FtServicesRepository? repository})
      : repository = repository ?? FtServicesRepository();

  final FtServicesRepository repository;

  @override
  State<FtServicesListScreen> createState() => _FtServicesListScreenState();
}

class _FtServicesListScreenState extends State<FtServicesListScreen> {
  final _search = TextEditingController();
  late Future<List<FtService>> _servicesFuture;
  String _category = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _servicesFuture = widget.repository.listServices();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _servicesFuture = widget.repository.listServices());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Future Times Services')),
        body: FutureBuilder<List<FtService>>(
          future: _servicesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _MessageState(
                message: 'Services could not be loaded. ${snapshot.error}',
                action: 'Try again',
                onPressed: _reload,
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final services = snapshot.data ?? const <FtService>[];
            final categories = services.map((item) => item.category).toSet();
            final filtered = services.where((service) {
              final matchesCategory =
                  _category == 'all' || service.category == _category;
              final matchesQuery = service.name
                  .toLowerCase()
                  .contains(_query.toLowerCase().trim());
              return matchesCategory && matchesQuery;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search services',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: _category == 'all',
                        onTap: () => setState(() => _category = 'all'),
                      ),
                      for (final category in categories)
                        _CategoryChip(
                          label: _label(category),
                          selected: _category == category,
                          onTap: () => setState(() => _category = category),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: Text(
                              'No services found in this category.',
                              style: TextStyle(color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, index) => FtServiceCard(
                            service: filtered[index],
                            fullWidth: true,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      );

  String _label(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.purple,
          backgroundColor: AppColors.surface,
          labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w700),
          side: BorderSide.none,
        ),
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(action)),
            ],
          ),
        ),
      );
}
