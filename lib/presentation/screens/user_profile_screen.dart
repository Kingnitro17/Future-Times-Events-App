import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/attendee_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../widgets/event_network_image.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.authRepository,
    required this.socialRepository,
    required this.eventRepository,
    this.initialData,
  });

  final String userId;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;
  final EventRepository eventRepository;
  final Object? initialData;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  List<EventModel> _attendingEvents = [];
  bool _loading = true;
  bool _following = false;
  bool _followActionLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initFromInitialData();
    _loadProfile();
  }

  void _initFromInitialData() {
    final init = widget.initialData;
    if (init is UserProfileCard) {
      _profile = {
        'id': init.userId,
        'display_name': init.displayName,
        'avatar_url': init.avatarUrl,
        'is_following': init.isFollowing,
        'is_friend': init.isFriend,
      };
      _following = init.isFollowing;
    } else if (init is AttendeeModel) {
      _profile = {
        'id': init.userId,
        'display_name': init.displayName,
        'avatar_url': init.avatarUrl,
        'is_friend': init.isFriend,
      };
    }
  }

  Future<void> _loadProfile() async {
    // If viewing own profile, redirect to main profile screen
    if (widget.authRepository.user?.id == widget.userId) {
      if (mounted) {
        context.go('/profile');
        return;
      }
    }

    setState(() => _loading = _profile == null);
    try {
      final profile =
          await widget.socialRepository.getUserProfile(widget.userId);
      if (profile == null && _profile == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'User profile not found.';
            _loading = false;
          });
        }
        return;
      }

      if (profile != null) {
        _profile = profile;
        _following = profile['is_following'] == true;
      }

      // Load events the user is attending
      final eventIds =
          await widget.socialRepository.getUserPublicEventIds(widget.userId);
      List<EventModel> events = [];
      if (eventIds.isNotEmpty) {
        events = await widget.eventRepository.getEventsByIds(eventIds);
      }

      if (mounted) {
        setState(() {
          _attendingEvents = events;
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_profile == null) {
            _errorMessage = 'Could not load profile. Please check your connection.';
          }
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (!widget.authRepository.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in from Profile to follow users.')),
      );
      return;
    }

    final newStatus = !_following;
    setState(() {
      _following = newStatus;
      _followActionLoading = true;
    });

    try {
      if (newStatus) {
        await widget.socialRepository.followUser(widget.userId);
      } else {
        await widget.socialRepository.unfollowUser(widget.userId);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _following = !newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update follow status.')),
        );
      }
    } finally {
      if (mounted) setState(() => _followActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null && _profile == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_rounded,
                    size: 56, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading && _profile == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final name = _profile?['display_name']?.toString() ?? 'User';
    final avatarUrl = _profile?['avatar_url']?.toString();
    final city = _profile?['city']?.toString() ?? 'Harare';
    final bio = _profile?['bio']?.toString();
    final isFriend = _profile?['is_friend'] == true;
    final eventsCount = _profile?['events_count'] ?? _attendingEvents.length;
    final followersCount = _profile?['followers_count'] ?? 0;
    final followingCount = _profile?['following_count'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Identity Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C0A0A14),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.purple.withValues(alpha: 0.12),
                            border: Border.all(color: AppColors.purple, width: 2.5),
                          ),
                          child: ClipOval(
                            child: avatarUrl != null && avatarUrl.trim().isNotEmpty
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _avatarFallback(name),
                                  )
                                : _avatarFallback(name),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                            if (isFriend) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Mutual Friend',
                                  style: TextStyle(
                                    color: AppColors.purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: AppColors.purple),
                            const SizedBox(width: 4),
                            Text(
                              city,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        if (bio != null && bio.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        // Follow / Unfollow CTA
                        SizedBox(
                          width: 180,
                          height: 42,
                          child: _following
                              ? OutlinedButton.icon(
                                  onPressed:
                                      _followActionLoading ? null : _toggleFollow,
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('Following',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.purple),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999)),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.brand,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _followActionLoading
                                        ? null
                                        : _toggleFollow,
                                    icon: const Icon(Icons.person_add_rounded,
                                        size: 18, color: Colors.white),
                                    label: const Text('Follow',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(999)),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        // Social Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem('Events', '$eventsCount'),
                            _statItem('Following', '$followingCount'),
                            _statItem('Followers', '$followersCount'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Public Events Attending
                  Row(
                    children: [
                      const Icon(Icons.event_available_rounded,
                          color: AppColors.purple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Events Attending (${_attendingEvents.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_attendingEvents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          '$name has not RSVPed to any public events yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attendingEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final event = _attendingEvents[index];
                        return Material(
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: InkWell(
                            onTap: () => context.push('/event/${event.id}',
                                extra: event),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 68,
                                      height: 68,
                                      child: EventNetworkImage.forEvent(event),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.name.text,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          event.venue?.name ?? 'Venue TBA',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          event.start.local.split('T').first,
                                          style: const TextStyle(
                                            color: AppColors.purple,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.purple,
          fontWeight: FontWeight.w900,
          fontSize: 32,
        ),
      ),
    );
  }
}
