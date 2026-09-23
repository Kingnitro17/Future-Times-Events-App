import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/roles/role_service.dart';

const _statusFilters = <String?, String>{
  'pending': 'Pending',
  'approved': 'Approved',
  'rejected': 'Rejected',
  null: 'All',
};

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({
    super.key,
    required this.authRepository,
    required this.adminRepository,
  });

  final AuthRepository authRepository;
  final AdminRepository adminRepository;

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  late Future<bool> _accessFuture;
  late Future<List<Map<String, dynamic>>> _applicationsFuture;
  String? _statusFilter = 'pending';
  String? _busyApplicationId;

  @override
  void initState() {
    super.initState();
    final userId = widget.authRepository.user?.id;
    _accessFuture = userId == null
        ? Future.value(false)
        : RoleService.instance.isSuperAdmin(userId);
    _applicationsFuture = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() => widget.adminRepository
      .getOrganizerApplications(statusFilter: _statusFilter);

  Future<void> _refresh() async {
    setState(() => _applicationsFuture = _fetch());
    await _applicationsFuture;
  }

  Future<void> _approve(Map<String, dynamic> application) async {
    final id = application['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _busyApplicationId = id);
    try {
      await widget.adminRepository.approveOrganizerApplication(id);
      if (!mounted) return;
      _removeOrRefresh(id, 'approved');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application approved')),
      );
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busyApplicationId = null);
    }
  }

  Future<void> _reject(Map<String, dynamic> application) async {
    final id = application['id']?.toString();
    if (id == null || id.isEmpty) return;
    final reason = await _rejectionReason();
    if (reason == null || !mounted) return;
    setState(() => _busyApplicationId = id);
    try {
      await widget.adminRepository.rejectOrganizerApplication(id, reason);
      if (!mounted) return;
      _removeOrRefresh(id, 'rejected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application rejected')),
      );
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _busyApplicationId = null);
    }
  }

  void _removeOrRefresh(String id, String newStatus) {
    setState(() {
      _applicationsFuture = _applicationsFuture.then((rows) {
        if (_statusFilter == null) {
          return rows
              .map((row) => row['id']?.toString() == id
                  ? {...row, 'status': newStatus}
                  : row)
              .toList();
        }
        return rows.where((row) => row['id']?.toString() != id).toList();
      });
    });
  }

  Future<String?> _rejectionReason() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject application'),
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
              hintText: 'Explain why this application was rejected',
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
        if (accessSnapshot.data != true) {
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
          appBar: AppBar(title: const Text('Organizer Applications')),
          body: Column(
            children: [
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final entry in _statusFilters.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _statusFilter == entry.key,
                          onSelected: (_) => setState(() {
                            _statusFilter = entry.key;
                            _applicationsFuture = _fetch();
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _applicationsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message:
                            'Could not load applications.\n${snapshot.error}',
                        onRetry: _refresh,
                      );
                    }
                    final applications = snapshot.data ?? const [];
                    if (applications.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Text('No applications here.',
                                  style: TextStyle(color: AppColors.textMuted)),
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: applications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final application = applications[index];
                          return _ApplicationCard(
                            application: application,
                            busy: _busyApplicationId ==
                                application['id']?.toString(),
                            disabled: _busyApplicationId != null,
                            onApprove: () => _approve(application),
                            onReject: () => _reject(application),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.busy,
    required this.disabled,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> application;
  final bool busy;
  final bool disabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final status = application['status']?.toString() ?? 'pending';
    final applicant = application['applicant'] as Map<String, dynamic>?;
    final applicantName = applicant?['display_name']?.toString() ??
        applicant?['email']?.toString() ??
        'Unknown applicant';
    final description = application['description']?.toString();
    final rejection = application['rejection_reason']?.toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application['business_name']?.toString() ?? 'Unnamed business',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 6),
            Text('Applicant: $applicantName',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Meta(Icons.schedule_outlined,
                    _date(application['created_at'])),
                if (application['contact_email'] != null)
                  _Meta(Icons.mail_outline,
                      application['contact_email'].toString()),
                if (application['contact_phone'] != null)
                  _Meta(Icons.phone_outlined,
                      application['contact_phone'].toString()),
                if (application['business_registration'] != null)
                  _Meta(Icons.badge_outlined,
                      application['business_registration'].toString()),
              ],
            ),
            if (description != null && description.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(description,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
            if (status == 'rejected' &&
                rejection != null &&
                rejection.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Reason: $rejection',
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12)),
            ],
            if (status == 'pending') ...[
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
                              child: CircularProgressIndicator(strokeWidth: 2))
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
          ],
        ),
      ),
    );
  }

  static String _date(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null
        ? 'Unknown date'
        : DateFormat('MMM d, yyyy').format(date);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.purple,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
