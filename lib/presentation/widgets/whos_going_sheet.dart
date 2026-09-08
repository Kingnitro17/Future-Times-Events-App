import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/attendee_model.dart';
import '../../data/repositories/social_repository.dart';

class WhosGoingSheet extends StatefulWidget {
  const WhosGoingSheet({
    super.key,
    required this.eventId,
    required this.socialRepository,
  });

  final String eventId;
  final SocialRepository socialRepository;

  static Future<void> show(
    BuildContext context, {
    required String eventId,
    required SocialRepository socialRepository,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhosGoingSheet(
        eventId: eventId,
        socialRepository: socialRepository,
      ),
    );
  }

  @override
  State<WhosGoingSheet> createState() => _WhosGoingSheetState();
}

class _WhosGoingSheetState extends State<WhosGoingSheet> {
  List<AttendeeModel> _attendees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list =
        await widget.socialRepository.getEventVisibleAttendees(widget.eventId);
    if (mounted) {
      setState(() {
        _attendees = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded,
                  color: AppColors.purple, size: 22),
              const SizedBox(width: 8),
              const Text(
                "Who's Going",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              Text(
                '${_attendees.length} public attendees',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else if (_attendees.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No public attendees yet. Be the first to say you are going!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _attendees.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final attendee = _attendees[index];
                  return ListTile(
                    tileColor: Colors.transparent,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/user/${attendee.userId}', extra: attendee);
                    },
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purple.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipOval(
                        child: attendee.avatarUrl != null &&
                                attendee.avatarUrl!.trim().isNotEmpty
                            ? Image.network(
                                attendee.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(attendee.displayName),
                              )
                            : _avatarFallback(attendee.displayName),
                      ),
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          attendee.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        if (attendee.isFriend) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text('Friend',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.purple)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: const Text(
                      'Going',
                      style: TextStyle(
                          color: AppColors.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.purple,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}
