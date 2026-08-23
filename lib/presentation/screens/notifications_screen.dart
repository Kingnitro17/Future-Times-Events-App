import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.notificationRepository,
  });

  final NotificationRepository notificationRepository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    widget.notificationRepository.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.notificationRepository,
          builder: (context, _) {
            final repo = widget.notificationRepository;
            if (repo.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5));
            }

            final items = repo.notifications;
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 52, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No notifications yet.',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Updates about your tickets, followed organizers, and friends will appear here.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Material(
                  color: item.read
                      ? AppColors.surface
                      : AppColors.purple.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: item.read
                          ? AppColors.border
                          : AppColors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      repo.markAsRead(item.id);
                      if (item.eventId != null && item.eventId!.isNotEmpty) {
                        context.push('/event/${item.eventId}');
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.purple.withValues(alpha: 0.12),
                            ),
                            child: Icon(
                              _iconForType(item.type),
                              color: AppColors.purple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: item.read
                                        ? FontWeight.w700
                                        : FontWeight.w900,
                                    fontSize: 14,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                                if (item.createdAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('MMM d, h:mm a')
                                        .format(item.createdAt!),
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'follower':
        return Icons.person_add_rounded;
      case 'ticket':
        return Icons.confirmation_number_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
