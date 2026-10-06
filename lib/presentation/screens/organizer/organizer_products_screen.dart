import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/organizer_product.dart';
import '../../../data/repositories/product_repository.dart';

class OrganizerProductsScreen extends StatefulWidget {
  const OrganizerProductsScreen({
    super.key,
    required this.eventId,
    required this.productRepository,
  });

  final String eventId;
  final ProductRepository productRepository;

  @override
  State<OrganizerProductsScreen> createState() =>
      _OrganizerProductsScreenState();
}

class _OrganizerProductsScreenState extends State<OrganizerProductsScreen> {
  late Future<List<OrganizerProduct>> _products;
  late Future<List<ProductPreorder>> _preorders;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _products = widget.productRepository.getManagedProducts(widget.eventId);
    _preorders = widget.productRepository.getEventPreorders(widget.eventId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_products, _preorders]);
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Products & Preorders'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Products'),
                Tab(text: 'Preorders'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final saved = await context.push<bool>(
                '/organizer/events/${widget.eventId}/products/new',
              );
              if (saved == true && mounted) _refresh();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add product'),
          ),
          body: TabBarView(
            children: [
              _ProductsList(
                future: _products,
                repository: widget.productRepository,
                onRefresh: _refresh,
                eventId: widget.eventId,
              ),
              _PreordersList(
                future: _preorders,
                repository: widget.productRepository,
                onRefresh: _refresh,
              ),
            ],
          ),
        ),
      );
}

class _ProductsList extends StatelessWidget {
  const _ProductsList({
    required this.future,
    required this.repository,
    required this.onRefresh,
    required this.eventId,
  });

  final Future<List<OrganizerProduct>> future;
  final ProductRepository repository;
  final Future<void> Function() onRefresh;
  final String eventId;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<OrganizerProduct>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error!, onRetry: onRefresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(
                child: Text('No products listed for this event.'));
          }
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  child: ListTile(
                    leading: _ProductThumbnail(url: product.imageUrl),
                    title: Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      '${product.currency} ${product.price.toStringAsFixed(2)}'
                      ' · ${product.stockQuantity == null ? 'Unlimited stock' : '${product.stockQuantity} in stock'}'
                      '${product.isActive ? '' : ' · Archived'}',
                    ),
                    onTap: () async {
                      final saved = await context.push<bool>(
                        '/organizer/events/$eventId/products/${product.id}/edit',
                        extra: product,
                      );
                      if (saved == true) onRefresh();
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final saved = await context.push<bool>(
                            '/organizer/events/$eventId/products/${product.id}/edit',
                            extra: product,
                          );
                          if (saved == true) onRefresh();
                        } else {
                          try {
                            await repository.archiveProduct(product.id);
                            await onRefresh();
                          } catch (error) {
                            if (context.mounted) {
                              _showMessage(
                                  context, 'Could not archive product: $error');
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (product.isActive)
                          const PopupMenuItem(
                              value: 'archive', child: Text('Archive')),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}

class _PreordersList extends StatelessWidget {
  const _PreordersList({
    required this.future,
    required this.repository,
    required this.onRefresh,
  });

  final Future<List<ProductPreorder>> future;
  final ProductRepository repository;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ProductPreorder>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error!, onRetry: onRefresh);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final preorders = snapshot.data!;
          if (preorders.isEmpty) {
            return const Center(child: Text('No preorders yet.'));
          }
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: preorders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final preorder = preorders[index];
                return Card(
                  child: ListTile(
                    title: Text(preorder.productName,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      '${preorder.quantity} × ${preorder.currency} '
                      '${preorder.unitPrice.toStringAsFixed(2)}'
                      '${preorder.notes?.isNotEmpty == true ? '\n${preorder.notes}' : ''}',
                    ),
                    isThreeLine: preorder.notes?.isNotEmpty == true,
                    trailing: DropdownButton<String>(
                      value: preorder.status,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'confirmed', child: Text('Confirmed')),
                        DropdownMenuItem(
                            value: 'fulfilled', child: Text('Fulfilled')),
                        DropdownMenuItem(
                            value: 'cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (status) async {
                        if (status == null) return;
                        try {
                          await repository.updatePreorderStatus(
                              preorder.id, status);
                          await onRefresh();
                        } catch (error) {
                          if (context.mounted) {
                            _showMessage(
                                context, 'Could not update preorder: $error');
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 52,
          height: 52,
          child: url?.isNotEmpty == true
              ? Image.network(url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
      );

  Widget _placeholder() => Container(
        color: AppColors.purple.withValues(alpha: .1),
        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.purple),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Could not load products: $error',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
