import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/wallet_item.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../widgets/qr_viewer.dart';
import '../widgets/wallet_item_card.dart';

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
    setState(() => _feedFuture = _loadFeed());
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
      return const Scaffold(
          body: Center(child: Text('Sign in to view your wallet.')));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Wallet')),
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
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
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
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.surfaceMuted,
          highlightColor: AppColors.surface,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 48, height: 48, color: AppColors.surfaceMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 16, color: AppColors.surfaceMuted),
                        const SizedBox(height: 10),
                        Container(
                            height: 12,
                            width: 180,
                            color: AppColors.surfaceMuted),
                        const SizedBox(height: 10),
                        Container(
                            height: 10,
                            width: 100,
                            color: AppColors.surfaceMuted),
                      ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _WalletEmpty extends StatelessWidget {
  const _WalletEmpty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 68, color: AppColors.purple),
              const SizedBox(height: 16),
              const Text('Nothing here yet — grab a ticket to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.go('/explore'),
                child: const Text('Discover events'),
              ),
            ],
          ),
        ),
      );
}

class _WalletError extends StatelessWidget {
  const _WalletError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load your wallet.'),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
