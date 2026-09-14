import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/organizer_application.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/organizer_repository.dart';

class OrganizerApplicationScreen extends StatefulWidget {
  const OrganizerApplicationScreen({
    super.key,
    required this.authRepository,
    required this.organizerRepository,
  });

  final AuthRepository authRepository;
  final OrganizerRepository organizerRepository;

  @override
  State<OrganizerApplicationScreen> createState() =>
      _OrganizerApplicationScreenState();
}

class _OrganizerApplicationScreenState
    extends State<OrganizerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _registration = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _description = TextEditingController();
  late Future<OrganizerApplication?> _applicationFuture;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = widget.authRepository.user?.email ?? '';
    _applicationFuture = widget.organizerRepository.getMyApplication();
  }

  @override
  void dispose() {
    _businessName.dispose();
    _registration.dispose();
    _phone.dispose();
    _email.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _isUser => widget.authRepository.currentRole == 'user';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.organizerRepository.submitApplication(
        businessName: _businessName.text,
        businessRegistration: _registration.text,
        contactPhone: _phone.text,
        contactEmail: _email.text,
        description: _description.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application submitted'),
          content: const Text(
              'Thanks for applying. We will review your application and respond within 48 hours.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Become an organizer')),
        body: _AlreadyOrganizer(onBack: () => context.pop()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Become an organizer')),
      body: FutureBuilder<OrganizerApplication?>(
        future: _applicationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              message: _friendlyError(snapshot.error!),
              onRetry: () => setState(() => _applicationFuture =
                  widget.organizerRepository.getMyApplication()),
            );
          }
          final application = snapshot.data;
          if (application?.isPending == true) {
            return const _PendingApplication();
          }
          return _ApplicationForm(
            formKey: _formKey,
            businessName: _businessName,
            registration: _registration,
            phone: _phone,
            email: _email,
            description: _description,
            rejectedApplication:
                application?.isRejected == true ? application : null,
            error: _error,
            submitting: _submitting,
            onSubmit: _submit,
          );
        },
      ),
    );
  }
}

class _AlreadyOrganizer extends StatelessWidget {
  const _AlreadyOrganizer({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded,
                  size: 64, color: AppColors.success),
              const SizedBox(height: 16),
              const Text("You're already an organizer",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              FilledButton(onPressed: onBack, child: const Text('Back')),
            ],
          ),
        ),
      );
}

class _PendingApplication extends StatelessWidget {
  const _PendingApplication();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 56, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text(
                    "Application pending review — we'll respond within 48 hours.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ApplicationForm extends StatelessWidget {
  const _ApplicationForm({
    required this.formKey,
    required this.businessName,
    required this.registration,
    required this.phone,
    required this.email,
    required this.description,
    required this.rejectedApplication,
    required this.error,
    required this.submitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController businessName;
  final TextEditingController registration;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController description;
  final OrganizerApplication? rejectedApplication;
  final String? error;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (rejectedApplication != null) ...[
            _Notice(
              color: AppColors.error,
              icon: Icons.info_outline_rounded,
              text:
                  'Your previous application was rejected${rejectedApplication!.rejectionReason?.isNotEmpty == true ? ': ${rejectedApplication!.rejectionReason}' : '.'} You can submit a new application.',
            ),
            const SizedBox(height: 16),
          ],
          const Text('Tell us about your organization',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Complete the form below to apply as an event organizer.',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          _field(businessName, 'Business name', Icons.business_outlined,
              required: true, maxLength: 100),
          _field(registration, 'Business registration (optional)',
              Icons.badge_outlined,
              maxLength: 100),
          _field(phone, 'Contact phone', Icons.phone_outlined,
              required: true,
              keyboardType: TextInputType.phone,
              validator: _phoneValidator),
          _field(email, 'Contact email', Icons.email_outlined,
              required: true,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator),
          _field(description, 'Description', Icons.description_outlined,
              required: true, maxLength: 500, maxLines: 5),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit application'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator ??
            (required
                ? (value) => value == null || value.trim().isEmpty
                    ? '$label is required'
                    : null
                : null),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  static String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact email is required';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact phone is required';
    }
    if (!RegExp(r'^\+?[0-9\s()\-]{7,20}$').hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
                child:
                    Text(text, style: TextStyle(color: color, height: 1.35))),
          ],
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
