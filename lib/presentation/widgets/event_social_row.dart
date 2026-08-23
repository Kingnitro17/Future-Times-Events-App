import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/social_repository.dart';
import 'whos_going_sheet.dart';

class EventSocialRow extends StatefulWidget {
  const EventSocialRow({
    super.key,
    required this.eventId,
    required this.socialRepository,
    required this.isSignedIn,
    this.onTap,
  });

  final String eventId;
  final SocialRepository socialRepository;
  final bool isSignedIn;
  final VoidCallback? onTap;

  @override
  State<EventSocialRow> createState() => _EventSocialRowState();
}

class _EventSocialRowState extends State<EventSocialRow> {
  EventSocialSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(EventSocialRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId ||
        oldWidget.isSignedIn != widget.isSignedIn) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final summary =
          await widget.socialRepository.getEventSocialSummary(widget.eventId);
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _summary = const EventSocialSummary();
          _loading = false;
        });
      }
    }
  }

  void _handleTap(BuildContext context) {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    WhosGoingSheet.show(
      context,
      eventId: widget.eventId,
      socialRepository: widget.socialRepository,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary ?? const EventSocialSummary();
    final totalGoing = s.goingCount;
    final friendCount = s.friendCount;
    final isSignedIn = widget.isSignedIn;

    Widget avatarContent;
    String labelText;

    if (isSignedIn && friendCount > 0) {
      // 1. SIGNED IN + friends_going > 0
      final avatars = s.friendAvatars.take(3).toList();
      avatarContent =
          _buildAvatarStack(avatars, defaultIcon: Icons.people_alt_rounded);
      labelText =
          '$friendCount ${friendCount == 1 ? "friend" : "friends"} going • $totalGoing going';
    } else if (isSignedIn && totalGoing > 0) {
      // 2. SIGNED IN + no friends + total_going > 0
      final avatars = s.publicAvatars.take(3).toList();
      avatarContent =
          _buildAvatarStack(avatars, defaultIcon: Icons.people_alt_rounded);
      labelText = '$totalGoing going';
    } else if (!isSignedIn && totalGoing > 0) {
      // 3. SIGNED OUT + total_going > 0
      final avatars = s.publicAvatars.take(2).toList();
      avatarContent = _buildLockBadgeStack(avatars);
      labelText = '$totalGoing going · Sign in to see friends';
    } else {
      // 4. ZERO REAL ATTENDEES (total_going == 0)
      avatarContent = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.people_outline_rounded,
            size: 13, color: AppColors.purple),
      );
      labelText = 'Be the first to go';
    }

    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatarContent,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _loading ? 'Loading attendees…' : labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack(List<String> avatars,
      {required IconData defaultIcon}) {
    if (avatars.isEmpty) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(defaultIcon, size: 13, color: AppColors.purple),
      );
    }

    final width = 14.0 * (avatars.length - 1) + 22.0;
    return SizedBox(
      height: 22,
      width: width,
      child: Stack(
        children: List.generate(avatars.length, (i) {
          return Positioned(
            left: i * 14.0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                color: AppColors.purple.withValues(alpha: 0.15),
              ),
              child: ClipOval(
                child: Image.network(
                  avatars[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    size: 12,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLockBadgeStack(List<String> publicAvatars) {
    final totalItems = 1 + publicAvatars.length;
    final width = 14.0 * (totalItems - 1) + 22.0;

    return SizedBox(
      height: 22,
      width: width,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E24),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child:
                  const Icon(Icons.lock_rounded, size: 11, color: Colors.white),
            ),
          ),
          ...List.generate(publicAvatars.length, (i) {
            return Positioned(
              left: (i + 1) * 14.0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  color: AppColors.purple.withValues(alpha: 0.15),
                ),
                child: ClipOval(
                  child: Image.network(
                    publicAvatars[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      size: 12,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
