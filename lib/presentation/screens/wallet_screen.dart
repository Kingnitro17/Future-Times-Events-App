import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/wallet_item.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../widgets/qr_viewer.dart';
import '../widgets/wallet_item_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/error_state.dart';
import '../widgets/common/skeleton.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    super.key,
    required this.authRepository,
    required this.walletRepository,
  });

  final AuthRepository authRepository;
  final WalletRepository walletRepository;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<List<WalletItem>> _feedFuture;
  StreamSubscription<List<WalletItem>>? _feedSubscription;
  List<WalletItem> _items = const [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _feedFuture = _loadFeed();
    _feedSubscription = widget.walletRepository.watchFeed().listen(
          _mergeRealtime,
          onError: (_) {},
        );
  }

  Future<List<WalletItem>> _loadFeed() async {
    final items = await widget.walletRepository.getFeed();
    if (mounted) setState(() => _items = items);
    return items;
  }

  void _mergeRealtime(List<WalletItem> incoming) {
    if (!mounted) return;
    final byId = <String, WalletItem>{
      for (final item in _items) '${item.kind}:${item.id}': item,
      for (final item in incoming) '${item.kind}:${item.id}': item,
    };
    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() => _items = merged);
  }

  Future<void> _refresh() async {
    _feedFuture = _loadFeed();
    if (mounted) setState(() {});
    await _feedFuture;
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    super.dispose();
  }

  List<WalletItem> get _filteredItems => _items.where((item) {
        if (_filter == 'Tickets') return item.kind == 'ticket';
        if (_filter == 'Payments') return item.kind == 'payment';
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    if (!widget.authRepository.isSignedIn) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Your wallet',
          message: 'Sign in to view your tickets and payments.',
          actionLabel: 'Sign in',
          onAction: () => context.go('/profile'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wallet', style: AppText.h1),
      ),
      body: FutureBuilder<List<WalletItem>>(
        future: _feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _WalletSkeleton();
          }
          if (snapshot.hasError) {
            return _WalletError(onRetry: _refresh);
          }
          final items = _filteredItems;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: _Filters(
                  value: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                )),
                if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _WalletEmpty(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => WalletItemCard(
                        item: items[index],
                        onTap: () => _openItem(items[index]),
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

  void _openItem(WalletItem item) {
    if (item.qrPayload != null) {
      QrViewer.show(context, item);
    } else if (item.kind == 'ticket') {
      context.push('/tickets');
    }
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
            ButtonSegment(value: 'Tickets', label: Text('Tickets')),
            ButtonSegment(value: 'Payments', label: Text('Payments')),
          ],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(0, 54)),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18))),
          ),
        ),
      );
}

class _WalletSkeleton extends StatelessWidget {
  const _WalletSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, __) => const SkeletonCard(),
      );
}

class _WalletEmpty extends StatelessWidget {
  const _WalletEmpty();

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Nothing here yet',
        message: 'Grab a ticket or make a payment to get started.',
        actionLabel: 'Discover events',
        onAction: () => context.go('/explore'),
      );
}

class _WalletError extends StatelessWidget {
  const _WalletError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ErrorState(onRetry: onRetry);
}
