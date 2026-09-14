import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/organizer_repository.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({
    super.key,
    required this.authRepository,
    required this.organizerRepository,
    this.eventId,
  });

  final AuthRepository authRepository;
  final OrganizerRepository organizerRepository;
  final String? eventId;

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _venueName = TextEditingController();
  final _venueAddress = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _picker = ImagePicker();
  final _tickets = <_TicketDraft>[_TicketDraft()];
  DateTime? _startsAt;
  DateTime? _endsAt;
  String? _category;
  String? _coverUrl;
  String? _status;
  String? _rejectionReason;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  static const _categories = [
    'Music',
    'Concerts',
    'Sports',
    'Comedy',
    'Festivals',
    'Nightlife',
    'Business',
    'Culture',
    'Community',
    'Family',
  ];

  bool get _isLocked =>
      _status == 'published' || _status == 'live' || _status == 'ended';

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    setState(() => _loading = true);
    try {
      final event =
          await widget.organizerRepository.getEventForEdit(widget.eventId!);
      if (event == null) {
        throw StateError('Event not found or not owned by you.');
      }
      final types =
          await widget.organizerRepository.getTicketTypes(widget.eventId!);
      _title.text = event['title']?.toString() ?? '';
      _description.text = event['description']?.toString() ?? '';
      _venueName.text =
          event['venue_name']?.toString() ?? event['venue']?.toString() ?? '';
      _venueAddress.text = event['address']?.toString() ?? '';
      _latitude.text = event['latitude']?.toString() ?? '';
      _longitude.text = event['longitude']?.toString() ?? '';
      _category = event['category']?.toString();
      _coverUrl = event['image_url']?.toString();
      _status = event['status']?.toString() ?? 'draft';
      _rejectionReason = event['rejection_reason']?.toString();
      _startsAt = DateTime.tryParse(event['starts_at']?.toString() ?? '');
      _endsAt = DateTime.tryParse(event['ends_at']?.toString() ?? '');
      _tickets
        ..clear()
        ..addAll(types.isEmpty
            ? [_TicketDraft()]
            : types.map(_TicketDraft.fromJson));
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCover() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      setState(() => _saving = true);
      _coverUrl = await widget.organizerRepository.uploadEventCover(
        await file.readAsBytes(),
        file.name,
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Cover upload failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDateTime({required bool start}) async {
    final initial = (start ? _startsAt : _endsAt) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      final value =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (start) {
        _startsAt = value;
      } else {
        _endsAt = value;
      }
    });
  }

  Future<void> _save({required bool submit}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null || _endsAt == null) {
      setState(() => _error = 'Choose both start and end times.');
      return;
    }
    if (!_endsAt!.isAfter(_startsAt!)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        'description': _description.text.trim(),
      };
      if (!_isLocked) {
        data.addAll({
          'title': _title.text.trim(),
          'category': _category,
          'image_url': _coverUrl,
          'venue_name': _venueName.text.trim(),
          'address': _venueAddress.text.trim(),
          'latitude': double.tryParse(_latitude.text.trim()),
          'longitude': double.tryParse(_longitude.text.trim()),
          'starts_at': _startsAt!.toIso8601String(),
          'ends_at': _endsAt!.toIso8601String(),
        });
      }
      final id =
          widget.eventId ?? await widget.organizerRepository.createEvent(data);
      if (widget.eventId != null) {
        await widget.organizerRepository.updateEvent(id, {
          ...data,
          if (!_isLocked) 'status': 'draft',
        });
      }
      await widget.organizerRepository.upsertTicketTypes(
        id,
        _tickets.map((ticket) => ticket.toJson()).toList(),
      );
      if (submit) {
        await widget.organizerRepository.submitEventForReview(id);
      }
      if (mounted) context.go('/organizer/events');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _venueName,
      _venueAddress,
      _latitude,
      _longitude,
    ]) {
      controller.dispose();
    }
    for (final ticket in _tickets) {
      ticket.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.authRepository.isSignedIn ||
        widget.authRepository.currentRole != 'organizer' &&
            widget.authRepository.currentRole != 'super_admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/profile');
      });
    }
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'Create Event' : 'Edit Event'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            if (_status == 'rejected')
              _Notice(
                color: AppColors.error,
                text:
                    'Rejected: ${_rejectionReason ?? 'Please update and resubmit.'}',
              ),
            if (_isLocked)
              const _Notice(
                color: AppColors.purple,
                text:
                    'Published events can only have descriptions and ticket quantities updated.',
              ),
            if (_error != null) _Notice(color: AppColors.error, text: _error!),
            _field(_title, 'Title', maxLength: 100, enabled: !_isLocked),
            _field(_description, 'Description', maxLength: 2000, maxLines: 5),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: _isLocked
                  ? null
                  : (value) => setState(() => _category = value),
              validator: (value) => value == null ? 'Choose a category' : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _saving || _isLocked ? null : _pickCover,
              icon: const Icon(Icons.image_outlined),
              label: Text(_coverUrl == null
                  ? 'Choose cover image'
                  : 'Replace cover image'),
            ),
            if (_coverUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child:
                    Image.network(_coverUrl!, height: 150, fit: BoxFit.cover),
              ),
            ],
            _field(_venueName, 'Venue name', enabled: !_isLocked),
            _field(_venueAddress, 'Venue address', enabled: !_isLocked),
            Row(
              children: [
                Expanded(
                    child: _field(_latitude, 'Latitude',
                        enabled: !_isLocked,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(_longitude, 'Longitude',
                        enabled: !_isLocked,
                        keyboardType: TextInputType.number)),
              ],
            ),
            _dateButton('Start', _startsAt, () => _pickDateTime(start: true),
                enabled: !_isLocked),
            _dateButton('End', _endsAt, () => _pickDateTime(start: false),
                enabled: !_isLocked),
            const SizedBox(height: 16),
            const Text('Ticket types',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ..._tickets
                .asMap()
                .entries
                .map((entry) => _ticketRow(entry.key, entry.value)),
            TextButton.icon(
              onPressed: _isLocked
                  ? null
                  : () => setState(() => _tickets.add(_TicketDraft())),
              icon: const Icon(Icons.add),
              label: const Text('Add ticket type'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : () => _save(submit: false),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save as draft'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed:
                  _saving || _isLocked ? null : () => _save(submit: true),
              child: const Text('Submit for review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label),
          validator: (value) => value == null || value.trim().isEmpty
              ? '$label is required'
              : null,
        ),
      );

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap,
          {required bool enabled}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          onPressed: enabled ? onTap : null,
          icon: const Icon(Icons.schedule),
          label: Text(
              '$label: ${value == null ? 'Choose date and time' : value.toLocal()}'),
        ),
      );

  Widget _ticketRow(int index, _TicketDraft ticket) => Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                  child: TextFormField(
                controller: ticket.name,
                enabled: !_isLocked,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              )),
              const SizedBox(width: 8),
              SizedBox(
                  width: 82,
                  child: TextFormField(
                    controller: ticket.price,
                    enabled: !_isLocked,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price'),
                    validator: (value) =>
                        num.tryParse(value ?? '') == null ? 'Invalid' : null,
                  )),
              const SizedBox(width: 8),
              SizedBox(
                  width: 82,
                  child: TextFormField(
                    controller: ticket.quantity,
                    enabled: !_isLocked,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    validator: (value) =>
                        int.tryParse(value ?? '') == null ? 'Invalid' : null,
                  )),
              IconButton(
                onPressed: _tickets.length == 1 || _isLocked
                    ? null
                    : () => setState(() {
                          final removed = _tickets.removeAt(index);
                          removed.dispose();
                        }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      );
}

class _TicketDraft {
  _TicketDraft({this.id, String? name, num? price, int? quantity})
      : name = TextEditingController(text: name ?? 'General Admission'),
        price = TextEditingController(text: (price ?? 0).toString()),
        quantity = TextEditingController(text: (quantity ?? 100).toString());

  factory _TicketDraft.fromJson(Map<String, dynamic> json) => _TicketDraft(
        id: json['id']?.toString(),
        name: json['name']?.toString(),
        price: num.tryParse(json['price']?.toString() ?? ''),
        quantity: int.tryParse(json['quantity_total']?.toString() ?? ''),
      );

  final String? id;
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController quantity;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name.text.trim(),
        'price': num.tryParse(price.text.trim()) ?? 0,
        'quantity_total': int.tryParse(quantity.text.trim()) ?? 0,
        'quantity_available': int.tryParse(quantity.text.trim()) ?? 0,
        'is_active': true,
        'is_visible': true,
      };

  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      );
}
