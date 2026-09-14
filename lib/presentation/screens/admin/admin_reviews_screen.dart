import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../presentation/widgets/event_network_image.dart';
import '../../../services/roles/role_service.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({
    super.key,
    required this.authRepository,
    required this.adminRepository,
  });

  final AuthRepository authRepository;
  final AdminRepository adminRepository;

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  late Future<bool> _accessFuture;
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  String? _busyEventId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final userId = widget.authRepository.user?.id;
    _accessFuture = userId == null
        ? Future.value(false)
        : RoleService.instance.isSuperAdmin(userId);
    _eventsFuture = widget.adminRepository.getPendingReviewEvents();
  }

  Future<void> _refresh() async {
    setState(
        () => _eventsFuture = widget.adminRepository.getPendingReviewEvents());
    await _eventsFuture;
  }

  Future<void> _approve(Map<String, dynamic> event) async {
    final id = event['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _busyEventId = id);
    try {
      await widget.adminRepository.approveEvent(id);
      if (!mounted) return;
      setState(() {
        _eventsFuture = _eventsFuture.then((rows) =>
            rows.where((row) => row['id']?.toString() != id).toList());
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Event approved')));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busyEventId = null);
    }
  }

  Future<void> _reject(Map<String, dynamic> event) async {
    final id = event['id']?.toString();
    if (id == null || id.isEmpty) return;
    final reason = await _rejectionReason();
    if (reason == null || !mounted) return;
    setState(() => _busyEventId = id);
    try {
      await widget.adminRepository.rejectEvent(id, reason);
      if (!mounted) return;
      setState(() {
        _eventsFuture = _eventsFuture.then((rows) =>
            rows.where((row) => row['id']?.toString() != id).toList());
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Event rejected')));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busyEventId = null);
    }
  }

  Future<String?> _rejectionReason() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject event'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 500,
            validator: (value) => value == null || value.trim().length < 10
                ? 'Enter at least 10 characters'
                : null,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Explain what needs to be changed',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action failed: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()));
        }
        final allowed = accessSnapshot.data == true;
        if (!allowed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/profile');
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Redirecting to your profile...')),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Review Queue')),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(onRetry: _refresh);
              }
              final events = snapshot.data ?? const [];
              if (events.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 220),
                      _EmptyState(),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _ReviewCard(
                      event: event,
                      busy: _busyEventId == event['id']?.toString(),
                      disabled: _busyEventId != null,
                      onTap: () => context.push(
                          '/admin/events/${event['id']?.toString() ?? ''}'),
                      onApprove: () => _approve(event),
                      onReject: () => _reject(event),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.event,
    required this.busy,
    required this.disabled,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> event;
  final bool busy;
  final bool disabled;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final title = event['title']?.toString() ?? 'Untitled event';
    final image = event['image_url']?.toString();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: EventNetworkImage(url: image),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                      'Organizer: ${event['organizer_display_name']?.toString() ?? 'Unknown'}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Meta(Icons.schedule_outlined,
                          '${_relative(event['submitted_at'])} submitted'),
                      _Meta(Icons.event_outlined,
                          _date(event['starts_at'] ?? event['date'])),
                      _Meta(Icons.confirmation_number_outlined,
                          '${event['ticket_types_count'] ?? 0} ticket types'),
                      _Meta(Icons.category_outlined,
                          event['category']?.toString() ?? 'Uncategorized'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: disabled ? null : onReject,
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: disabled ? null : onApprove,
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relative(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Unknown time';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String _date(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null ? 'Date TBA' : DateFormat('MMM d, yyyy').format(date);
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 72, color: AppColors.success.withValues(alpha: .85)),
              const SizedBox(height: 16),
              const Text("Nothing to review — you're all caught up",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Could not load the review queue.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
