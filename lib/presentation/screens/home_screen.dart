import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/blocs/event/event_bloc.dart';
import '../../logic/blocs/event/event_event.dart';
import '../../logic/blocs/event/event_state.dart';
import '../widgets/adaptive_wrapper.dart';
import '../widgets/event_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  String _selectedCategoryName = 'All';

  @override
  void initState() {
    super.initState();
    context.read<EventBloc>().add(const FetchEvents());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategoryTap(String id, String name) {
    setState(() {
      _selectedCategory = id;
      _selectedCategoryName = name;
    });
    context.read<EventBloc>().add(
          FilterByCategory(categoryId: id, categoryName: name),
        );
  }

  void _onSearch(String query) {
    context.read<EventBloc>().add(SearchEvents(query: query));
  }

  Future<void> _onRefresh() async {
    context.read<EventBloc>().add(const FetchEvents(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<EventBloc>(),
        child: const _FilterBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSliverScaffold(
      title: 'Discover',
      onRefresh: _onRefresh,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          tooltip: 'Filter',
          onPressed: _openFilterSheet,
        ),
      ],
      slivers: [
        // ── Search Bar ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: _SearchBar(
              controller: _searchController,
              onChanged: _onSearch,
            ),
          ),
        ),

        // ── Category Chips ──────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _CategoryChips(
            selected: _selectedCategory,
            onTap: _onCategoryTap,
          ),
        ),

        // ── Active Filter Indicator ─────────────────────────────────────
        BlocBuilder<EventBloc, EventState>(
          builder: (context, state) {
            if (state is EventLoaded && state.hasActiveFilters) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 14,
                        color: AppTheme.electricIndigo,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Filters active',
                        style: TextStyle(
                          color: AppTheme.electricIndigo,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            context.read<EventBloc>().add(const ClearFilters()),
                        child: const Text(
                          'Clear all',
                          style: TextStyle(
                            color: AppTheme.subtleGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),

        // ── Event Grid ──────────────────────────────────────────────────
        BlocBuilder<EventBloc, EventState>(
          builder: (context, state) {
            if (state is EventLoading) {
              return _buildSkeletonGrid();
            }

            if (state is EventError) {
              return SliverFillRemaining(
                child: _ErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<EventBloc>().add(const FetchEvents()),
                ),
              );
            }

            if (state is EventLoaded) {
              if (state.events.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyView(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: state.events.length + (state.isPaginating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.events.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: AppTheme.electricIndigo,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }

                    final event = state.events[index];

                    // Trigger pagination near the end
                    if (index == state.events.length - 4 && state.hasMore) {
                      context.read<EventBloc>().add(const LoadMoreEvents());
                    }

                    // Animate list items with a slight stagger based on index modulo
                    final delayMs = (index % 10) * 50;

                    return EventCard(
                      event: event,
                      heroTag: 'event_${event.id}',
                      onTap: () => context.push(
                        '/event/${event.id}',
                        extra: event,
                      ),
                    )
                        .animate()
                        .fade(duration: 400.ms, delay: delayMs.ms)
                        .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 400.ms,
                            curve: Curves.easeOut);
                  },
                ),
              );
            }

            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }

  SliverPadding _buildSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 16,
          childAspectRatio: 0.88,
        ),
        itemCount: 5,
        itemBuilder: (_, __) => const EventCardSkeleton(),
      ),
    );
  }
}

// ── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.pureWhite),
      decoration: InputDecoration(
        hintText: 'Search events, venues...',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.subtleGrey,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon:
                    const Icon(Icons.close_rounded, color: AppTheme.subtleGrey),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
      ),
    );
  }
}

// ── Category Chips ────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onTap});

  final String selected;
  final void Function(String id, String name) onTap;

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.kCategories.entries.toList();

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = categories[index];
          final isSelected = selected == entry.value;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterChip(
              label: Text(entry.key),
              selected: isSelected,
              onSelected: (_) => onTap(entry.value, entry.key),
              selectedColor: AppTheme.electricIndigo,
              checkmarkColor: AppTheme.pureWhite,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.pureWhite : AppTheme.subtleGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet();

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _isFree;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.charcoalBorder,
                borderRadius: AppTheme.radiusPill,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Filter Events',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // Price toggle
          Text('Price', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterChipOption(
                label: 'All',
                selected: _isFree == null,
                onTap: () => setState(() => _isFree = null),
              ),
              const SizedBox(width: 8),
              _FilterChipOption(
                label: 'Free',
                selected: _isFree == true,
                onTap: () => setState(() => _isFree = true),
              ),
              const SizedBox(width: 8),
              _FilterChipOption(
                label: 'Paid',
                selected: _isFree == false,
                onTap: () => setState(() => _isFree = false),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date range
          Text('Date Range', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: _startDate == null
                      ? 'From'
                      : '${_startDate!.day}/${_startDate!.month}',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.electricIndigo,
                            surface: AppTheme.charcoalSurface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: _endDate == null
                      ? 'To'
                      : '${_endDate!.day}/${_endDate!.month}',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.electricIndigo,
                            surface: AppTheme.charcoalSurface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Apply
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.read<EventBloc>().add(ApplyFilters(
                      startDate: _startDate,
                      endDate: _endDate,
                      isFree: _isFree,
                    ));
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipOption extends StatelessWidget {
  const _FilterChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.electricIndigo : AppTheme.charcoalCard,
          borderRadius: AppTheme.radiusPill,
          border: Border.all(
            color: selected ? AppTheme.electricIndigo : AppTheme.charcoalBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.pureWhite : AppTheme.subtleGrey,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.charcoalCard,
          borderRadius: AppTheme.radiusMedium,
          border: Border.all(color: AppTheme.charcoalBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 14, color: AppTheme.electricIndigo),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.offWhite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / Error States ───────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 72,
            color: AppTheme.charcoalBorder,
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(color: AppTheme.subtleGrey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 72,
              color: AppTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppTheme.subtleGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
