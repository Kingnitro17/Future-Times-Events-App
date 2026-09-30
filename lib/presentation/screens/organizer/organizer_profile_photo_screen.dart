import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';

class OrganizerProfilePhotoScreen extends StatefulWidget {
  const OrganizerProfilePhotoScreen({
    super.key,
    required this.authRepository,
    required this.returnLocation,
  });

  final AuthRepository authRepository;
  final String? returnLocation;

  @override
  State<OrganizerProfilePhotoScreen> createState() =>
      _OrganizerProfilePhotoScreenState();
}

class _OrganizerProfilePhotoScreenState
    extends State<OrganizerProfilePhotoScreen> {
  final _imagePicker = ImagePicker();
  bool _uploading = false;
  String? _error;

  String? get _avatarUrl =>
      widget.authRepository.profile?['avatar_url']?.toString() ??
      widget.authRepository.user?.userMetadata?['avatar_url']?.toString();

  String get _safeReturnLocation {
    final location = widget.returnLocation;
    if (location != null &&
        location.startsWith('/organizer') &&
        location != '/organizer/complete-profile') {
      return location;
    }
    return '/organizer';
  }

  Future<void> _pickPhoto() async {
    XFile? image;
    try {
      image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Could not open your photo library. Try again.');
      }
      return;
    }
    if (image == null || !mounted) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await widget.authRepository.updateProfilePhoto(
        await image.readAsBytes(),
        fileName: image.name,
        contentType: image.mimeType,
      );
      if (mounted) context.go(_safeReturnLocation);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not upload your photo. Try again.');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrl;
    final name = widget.authRepository.profile?['display_name']?.toString() ??
        widget.authRepository.user?.email?.split('@').first ??
        'Organizer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Complete organizer profile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.purple.withValues(alpha: .12),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            name.isEmpty ? 'O' : name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.purple,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Add a profile photo to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Organizers need a profile photo before accessing event '
                    'management and ticket-scanning tools. Your photo helps '
                    'attendees recognize the event host.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _uploading ? null : _pickPhoto,
                      icon: _uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_a_photo_outlined),
                      label: Text(_uploading
                          ? 'Uploading photo…'
                          : avatarUrl == null || avatarUrl.isEmpty
                              ? 'Choose profile photo'
                              : 'Change profile photo'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _uploading ? null : () => context.go('/profile'),
                    child: const Text('Return to profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
