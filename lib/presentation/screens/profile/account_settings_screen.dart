import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/zimbabwe_locations_repository.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  String? _city;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.authRepository.profile;
    final user = widget.authRepository.user;

    final initialName = profile?['display_name']?.toString() ??
        user?.userMetadata?['display_name']?.toString() ??
        user?.userMetadata?['full_name']?.toString() ??
        '';
    final initialPhone = profile?['phone']?.toString() ?? '';
    final initialCity = profile?['city']?.toString() ?? '';
    final initialBio = profile?['bio']?.toString() ?? '';

    _nameController = TextEditingController(text: initialName);
    _phoneController = TextEditingController(text: initialPhone);
    _city = initialCity.isEmpty ? null : initialCity;
    _bioController = TextEditingController(text: initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final city = _city?.trim() ?? '';
      final bio = _bioController.text.trim();

      await widget.authRepository.updateProfileDetails(
        displayName: name,
        phone: phone,
        city: city,
        bio: bio,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account settings saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failure.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Failed to save settings. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _requestAccountDeletion() async {
    final confirmationController = TextEditingController();
    final confirmationFormKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Request account deletion?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account deletion must be completed by support so associated '
              'tickets and payment records can be handled safely. Type DELETE '
              'to open a deletion request email.',
            ),
            const SizedBox(height: 16),
            Form(
              key: confirmationFormKey,
              child: TextFormField(
                controller: confirmationController,
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value?.trim() == 'DELETE'
                    ? null
                    : 'Enter DELETE to continue',
                decoration: const InputDecoration(labelText: 'Type DELETE'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (confirmationFormKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    confirmationController.dispose();
    if (confirmed != true || !mounted) return;

    final userEmail = widget.authRepository.user?.email ?? '';
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@futuretimesevents.com',
      queryParameters: {
        'subject': 'Account deletion request',
        'body': 'Please help me delete my Future Times account.'
            '${userEmail.isEmpty ? '' : '\nAccount email: $userEmail'}',
      },
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Email support@futuretimesevents.com to complete your deletion request.',
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authRepository.user;
    const locations = ZimbabweLocationsRepository.allLocations;
    final cityOptions = <String>{
      if (_city != null &&
          !locations.any((location) => location.displayName == _city))
        _city!,
      ...locations.map((location) => location.displayName),
    }.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Personal Info Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PERSONAL INFORMATION',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_saving,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter your name'
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Display Name / Full Name',
                          hintText: 'e.g. Tendai Moyo',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: user?.email ?? 'Not available',
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                          helperText:
                              'To change your email address, contact support.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Contact & Location Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONTACT & LOCATION',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_saving,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+263 77 123 4567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _city,
                        items: cityOptions
                            .map((city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                ))
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _city = value),
                        menuMaxHeight: 360,
                        decoration: const InputDecoration(
                          labelText: 'Primary City / Location',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Bio Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ABOUT YOU',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        enabled: !_saving,
                        maxLines: 3,
                        maxLength: 250,
                        decoration: const InputDecoration(
                          labelText: 'Bio / Personal Note',
                          hintText: 'Share a little about yourself...',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save Button
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: _saving ? null : _requestAccountDeletion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text('Request account deletion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
