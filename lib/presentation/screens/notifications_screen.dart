import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/notification_repository.dart';
import '../widgets/common/empty_state.dart';

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
    unawaited(widget.notificationRepository.fetchNotifications());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Notifications')),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: widget.notificationRepository,
            builder: (context, _) {
              final repo = widget.notificationRepository;
              if (repo.isLoading && repo.notifications.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                );
              }
              if (repo.lastError != null && repo.notifications.isEmpty) {
                return EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Notifications unavailable',
                  message: repo.lastError!,
                  actionLabel: 'Try again',
                  onAction: () => unawaited(repo.fetchNotifications()),
                );
              }
              if (repo.notifications.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications yet',
                  message:
                      'Updates about your tickets, followed organizers, and friends will appear here.',
                );
              }

              final cutoff = DateTime.now().subtract(const Duration(days: 1));
              final newItems = repo.notifications
                  .where((item) =>
                      item.createdAt != null && item.createdAt!.isAfter(cutoff))
                  .toList();
              final earlierItems = repo.notifications
                  .where((item) =>
                      item.createdAt == null ||
                      !item.createdAt!.isAfter(cutoff))
                  .toList();

              return RefreshIndicator(
                onRefresh: repo.fetchNotifications,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (repo.lastError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MaterialBanner(
                          content: Text(repo.lastError!),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  unawaited(repo.fetchNotifications()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    if (newItems.isNotEmpty) ...[
                      const _GroupHeading('New'),
                      ...newItems.map((item) => _notificationTile(repo, item)),
                    ],
                    if (earlierItems.isNotEmpty) ...[
                      const _GroupHeading('Earlier'),
                      ...earlierItems
                          .map((item) => _notificationTile(repo, item)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );

  Widget _notificationTile(
    NotificationRepository repository,
    NotificationModel item,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) => _deleteNotification(repository, item.id),
          child: Material(
            color: item.read
                ? AppColors.surface
                : AppColors.purple.withValues(alpha: .05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: item.read
                    ? AppColors.border
                    : AppColors.purple.withValues(alpha: .3),
              ),
            ),
            child: InkWell(
              onTap: () => _openNotification(repository, item),
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
                        color: AppColors.purple.withValues(alpha: .12),
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
                              fontWeight:
                                  item.read ? FontWeight.w700 : FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                          if (item.body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (item.createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _relativeTime(item.createdAt!),
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
          ),
        ),
      );

  Future<void> _openNotification(
    NotificationRepository repository,
    NotificationModel item,
  ) async {
    try {
      if (!item.read) await repository.markAsRead(item.id);
      if (!mounted) return;
      final route = item.payload['route']?.toString();
      if (route != null && route.startsWith('/') && !route.startsWith('//')) {
        context.push(route);
      } else if (item.eventId != null && item.eventId!.isNotEmpty) {
        context.push('/event/${Uri.encodeComponent(item.eventId!)}');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open notification: $error')),
      );
    }
  }

  Future<void> _deleteNotification(
    NotificationRepository repository,
    String notificationId,
  ) async {
    try {
      await repository.deleteNotification(notificationId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not dismiss notification: $error')),
      );
      unawaited(repository.fetchNotifications());
    }
  }

  String _relativeTime(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(date);
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'follower':
        return Icons.person_add_rounded;
      case 'ticket':
        return Icons.confirmation_number_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'group_invite':
        return Icons.group_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
        ),
      );
}
