import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/organizer_product.dart';
import '../../data/repositories/product_repository.dart';

class ProductPreorderScreen extends StatefulWidget {
  const ProductPreorderScreen({
    super.key,
    required this.eventId,
    required this.productRepository,
  });

  final String eventId;
  final ProductRepository productRepository;

  @override
  State<ProductPreorderScreen> createState() => _ProductPreorderScreenState();
}

class _ProductPreorderScreenState extends State<ProductPreorderScreen> {
  late Future<List<OrganizerProduct>> _products;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _products = widget.productRepository.getEventProducts(widget.eventId);

  Future<void> _preorder(OrganizerProduct product) async {
    final quantityController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preorder ${product.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${product.currency} ${product.price.toStringAsFixed(2)} each'),
          const SizedBox(height: 12),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(quantityController.text.trim());
              if (value == null || value < 1) return;
              Navigator.pop(context, value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    quantityController.dispose();
    if (quantity == null || !mounted) {
      notesController.dispose();
      return;
    }
    final notes = notesController.text;
    notesController.dispose();
    try {
      await widget.productRepository.createPreorder(
        productId: product.id,
        quantity: quantity,
        notes: notes,
      );
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preorder placed. No payment has been collected.'),
      ));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place preorder: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Organizer products')),
        body: FutureBuilder<List<OrganizerProduct>>(
          future: _products,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load products: ${snapshot.error}'),
              ));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = snapshot.data!;
            if (products.isEmpty) {
              return const Center(
                  child: Text('No organizer products available.'));
            }
            return RefreshIndicator(
              onRefresh: () async => setState(_load),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (product.imageUrl?.isNotEmpty == true)
                          Image.network(
                            product.imageUrl!,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900)),
                              if (product.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(product.description!,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                              ],
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                  child: Text(
                                    '${product.currency} ${product.price.toStringAsFixed(2)}'
                                    ' · ${product.stockQuantity == null ? 'Available' : '${product.stockQuantity} left'}',
                                    style: const TextStyle(
                                        color: AppColors.purple,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: product.isAvailable
                                      ? () => _preorder(product)
                                      : null,
                                  child: const Text('Preorder'),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}
