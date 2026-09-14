import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/attendance_group_repository.dart';
import '../../../data/repositories/event_repository.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({
    super.key,
    required this.eventId,
    required this.eventRepository,
    required this.groupRepository,
    this.friendCount,
  });

  final String eventId;
  final EventRepository eventRepository;
  final AttendanceGroupRepository groupRepository;
  final int? friendCount;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _meetingPointController = TextEditingController();
  EventModel? _event;
  DateTime? _meetingTime;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      _event = await widget.eventRepository.getEventById(widget.eventId);
      final eventName = _event?.name.text ?? 'this event';
      _nameController.text = widget.friendCount == null
          ? 'Going to $eventName'
          : 'Going to $eventName with ${widget.friendCount} friends';
    } catch (error) {
      _error = 'Could not load the event. Try again.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickMeetingTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _meetingTime ?? DateTime.now(),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_meetingTime ?? DateTime.now()),
    );
    if (pickedTime == null) return;
    setState(() {
      _meetingTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final groupId = await widget.groupRepository.createGroup(
        eventId: widget.eventId,
        name: _nameController.text.trim(),
        meetingPoint: _meetingPointController.text.trim().isEmpty
            ? null
            : _meetingPointController.text.trim(),
        meetingTime: _meetingTime,
      );
      if (!mounted) return;
      context.go('/groups/$groupId');
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _meetingPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create a group'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _error != null && _event == null
          ? _ErrorState(
              message: _error!,
              onRetry: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadEvent();
              })
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    'Coordinate your plans with friends attending this event.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Group name',
                      prefixIcon: Icon(Icons.groups_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a group name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _meetingPointController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Meeting point (optional)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: const Icon(Icons.schedule_rounded,
                          color: AppColors.purple),
                      title: Text(_meetingTime == null
                          ? 'Meeting time (optional)'
                          : _formatDateTime(_meetingTime!)),
                      subtitle: _meetingTime == null
                          ? const Text('Let your group know when to meet')
                          : null,
                      trailing: _meetingTime == null
                          ? const Icon(Icons.chevron_right_rounded)
                          : IconButton(
                              onPressed: () =>
                                  setState(() => _meetingTime = null),
                              icon: const Icon(Icons.clear_rounded),
                            ),
                      onTap: _pickMeetingTime,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create group'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month}/${local.year} at $hour:$minute $period';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}
