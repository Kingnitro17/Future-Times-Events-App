import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/social_repository.dart';

class EventSocialRow extends StatefulWidget {
  const EventSocialRow({
    super.key,
    required this.eventId,
    required this.socialRepository,
    required this.isSignedIn,
  });

  final String eventId;
  final SocialRepository socialRepository;
  final bool isSignedIn;

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

  Future<void> _load() async {
    final res = await widget.socialRepository.getEventSocialSummary(widget.eventId);
    if (mounted) {
      setState(() {
        _summary = res;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _summary == null || _summary!.goingCount == 0) {
      return const SizedBox.shrink();
    }

    final s = _summary!;
    final avatars = widget.isSignedIn && s.friendAvatars.isNotEmpty
        ? s.friendAvatars.take(3).toList()
        : s.publicAvatars.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatars.isNotEmpty) ...[
            SizedBox(
              height: 20,
              width: 14.0 * (avatars.length - 1) + 20.0,
              child: Stack(
                children: List.generate(avatars.length, (i) {
                  return Positioned(
                    left: i * 14.0,
                    child: Container(
                      width: 20,
                      height: 20,
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
                            Icons.person,
                            size: 11,
                            color: AppColors.purple,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              widget.isSignedIn && s.friendCount > 0
                  ? '${s.goingCount} going • ${s.friendCount} ${s.friendCount == 1 ? "friend" : "friends"}'
                  : '${s.goingCount} going',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
