import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/social_repository.dart';

class OrganizerDetailScreen extends StatefulWidget {
  const OrganizerDetailScreen({
    super.key,
    required this.organizer,
    required this.socialRepository,
  });

  final OrganizerModel organizer;
  final SocialRepository socialRepository;

  @override
  State<OrganizerDetailScreen> createState() => _OrganizerDetailScreenState();
}

class _OrganizerDetailScreenState extends State<OrganizerDetailScreen> {
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.organizer.isFollowing;
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.organizer;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(org.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Organizer Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.purple, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: org.logoUrl != null
                      ? Image.network(org.logoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(org.name))
                      : _avatarFallback(org.name),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    org.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text),
                  ),
                  if (org.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: AppColors.purple, size: 20),
                  ],
                ],
              ),
              if (org.location != null) ...[
                const SizedBox(height: 4),
                Text(
                  '📍 ${org.location}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 16),
              // Followers pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${org.followersCount} Followers',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.purple, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              // Follow CTA
              SizedBox(
                width: 200,
                height: 44,
                child: _isFollowing
                    ? OutlinedButton(
                        onPressed: () async {
                          setState(() => _isFollowing = false);
                          await widget.socialRepository.unfollowUser(org.id);
                        },
                        child: const Text('Following'),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() => _isFollowing = true);
                            await widget.socialRepository.followUser(org.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text('Follow Organizer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                      ),
              ),
              const SizedBox(height: 28),
              if (org.description != null && org.description!.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ABOUT ORGANIZER',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    org.description!,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.45, fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'O';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w900, fontSize: 32),
      ),
    );
  }
}
