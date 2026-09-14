import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/venue_table.dart';
import '../../../data/repositories/venue_commerce_repository.dart';

class EditTableScreen extends StatefulWidget {
  const EditTableScreen({
    super.key,
    required this.eventId,
    required this.venueRepository,
    this.table,
  });

  final String eventId;
  final VenueCommerceRepository venueRepository;
  final VenueTable? table;

  @override
  State<EditTableScreen> createState() => _EditTableScreenState();
}

class _EditTableScreenState extends State<EditTableScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _zone;
  late final TextEditingController _capacity;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  String _status = 'available';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final table = widget.table;
    _name = TextEditingController(text: table?.name);
    _zone = TextEditingController(text: table?.zone);
    _capacity = TextEditingController(text: table?.capacity.toString() ?? '2');
    _price = TextEditingController(text: table?.price.toString() ?? '0');
    _currency = TextEditingController(text: table?.currency ?? 'USD');
    _status = table?.status ?? 'available';
  }

  @override
  void dispose() {
    for (final controller in [_name, _zone, _capacity, _price, _currency]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.venueRepository.upsertTable({
        if (widget.table != null) 'id': widget.table!.id,
        'event_id': widget.eventId,
        'name': _name.text.trim(),
        'zone': _zone.text.trim().isEmpty ? null : _zone.text.trim(),
        'capacity': int.parse(_capacity.text.trim()),
        'price': double.parse(_price.text.trim()),
        'currency': _currency.text.trim().toUpperCase(),
        'status': _status,
      });
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save table: $error')),
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
          title: Text(widget.table == null ? 'Add table' : 'Edit table'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
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
                decoration: const InputDecoration(labelText: 'Table name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _zone,
                decoration: const InputDecoration(labelText: 'Zone'),
              ),
              TextFormField(
                controller: _capacity,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = int.tryParse(value?.trim() ?? '');
                  return amount == null || amount <= 0
                      ? 'Enter a capacity greater than 0'
                      : null;
                },
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
                controller: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const ['available', 'reserved', 'occupied', 'closed']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save table'),
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
