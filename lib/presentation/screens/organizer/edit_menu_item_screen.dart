import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/menu_item.dart';
import '../../../data/repositories/organizer_repository.dart';
import '../../../data/repositories/venue_commerce_repository.dart';

class EditMenuItemScreen extends StatefulWidget {
  const EditMenuItemScreen({
    super.key,
    required this.eventId,
    required this.venueRepository,
    required this.organizerRepository,
    this.item,
  });

  final String eventId;
  final VenueCommerceRepository venueRepository;
  final OrganizerRepository organizerRepository;
  final MenuItem? item;

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _stock;
  String? _imageUrl;
  bool _available = true;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name);
    _description = TextEditingController(text: item?.description);
    _price = TextEditingController(text: item?.price.toString() ?? '');
    _category = TextEditingController(text: item?.category);
    _stock = TextEditingController(text: item?.stock.toString() ?? '');
    _imageUrl = item?.imageUrl;
    _available = item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _price,
      _category,
      _stock,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      _imageUrl = await widget.organizerRepository.uploadEventCover(
        await file.readAsBytes(),
        file.name,
      );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.venueRepository.upsertMenuItem({
        if (widget.item != null) 'id': widget.item!.id,
        'event_id': widget.eventId,
        'name': _name.text.trim(),
        'description':
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        'price': double.parse(_price.text.trim()),
        'category':
            _category.text.trim().isEmpty ? null : _category.text.trim(),
        'image_url': _imageUrl,
        'is_available': _available,
        'stock':
            _stock.text.trim().isEmpty ? null : int.parse(_stock.text.trim()),
        'currency': 'USD',
      });
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save menu item: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.item == null ? 'Add menu item' : 'Edit menu item'),
          actions: [
            TextButton(
              onPressed: _saving || _uploading ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  return amount == null || amount < 0
                      ? 'Enter a valid non-negative price'
                      : null;
                },
              ),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: _stock,
                decoration:
                    const InputDecoration(labelText: 'Stock (optional)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final stock = int.tryParse(value.trim());
                  return stock == null || stock < 0 ? 'Enter 0 or more' : null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available'),
                value: _available,
                onChanged: (value) => setState(() => _available = value),
              ),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(_uploading
                    ? 'Uploading...'
                    : _imageUrl == null
                        ? 'Choose image'
                        : 'Replace image'),
              ),
              if (_imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.network(
                    _imageUrl!,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving || _uploading ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save menu item'),
              ),
              TextButton(
                onPressed: _saving ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
}
