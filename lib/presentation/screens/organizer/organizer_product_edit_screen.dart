import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/organizer_product.dart';
import '../../../data/repositories/product_repository.dart';

class OrganizerProductEditScreen extends StatefulWidget {
  const OrganizerProductEditScreen({
    super.key,
    required this.eventId,
    required this.productRepository,
    this.product,
  });

  final String eventId;
  final ProductRepository productRepository;
  final OrganizerProduct? product;

  @override
  State<OrganizerProductEditScreen> createState() =>
      _OrganizerProductEditScreenState();
}

class _OrganizerProductEditScreenState
    extends State<OrganizerProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _stock;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _imageUrl = TextEditingController(text: product?.imageUrl ?? '');
    _price = TextEditingController(text: product?.price.toString() ?? '');
    _currency = TextEditingController(text: product?.currency ?? 'USD');
    _stock =
        TextEditingController(text: product?.stockQuantity?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _price.dispose();
    _currency.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.productRepository.saveProduct(
        productId: widget.product?.id,
        eventId: widget.eventId,
        name: _name.text,
        description: _description.text,
        imageUrl: _imageUrl.text,
        price: double.parse(_price.text.trim()),
        currency: _currency.text,
        stockQuantity:
            _stock.text.trim().isEmpty ? null : int.parse(_stock.text.trim()),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save product: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.product == null ? 'Add product' : 'Edit product'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 12),
              ],
              _field(_name, 'Product name', required: true, maxLength: 100),
              _field(_description, 'Description', maxLines: 4),
              _field(_imageUrl, 'Image URL'),
              Row(children: [
                Expanded(
                    flex: 2,
                    child:
                        _field(_price, 'Price', required: true, numeric: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_currency, 'Currency', required: true)),
              ]),
              _field(_stock, 'Stock quantity (leave blank for unlimited)',
                  numeric: true),
              const SizedBox(height: 16),
              const Text(
                'Preorders are created as pending requests; payment is not collected in this step.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    int maxLines = 1,
    int? maxLength,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) return 'This field is required.';
            if (numeric && text.isNotEmpty && num.tryParse(text) == null) {
              return 'Enter a valid number.';
            }
            if (label == 'Price' &&
                num.tryParse(text) != null &&
                num.parse(text) < 0) {
              return 'Price cannot be negative.';
            }
            if (label.startsWith('Stock') &&
                text.isNotEmpty &&
                (int.tryParse(text) == null || int.parse(text) < 0)) {
              return 'Enter a whole number of zero or more.';
            }
            if (label == 'Currency' && text.length != 3) {
              return 'Use a 3-letter currency code.';
            }
            return null;
          },
        ),
      );
}
