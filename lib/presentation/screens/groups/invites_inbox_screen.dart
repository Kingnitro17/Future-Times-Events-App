import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/attendance_group.dart';
import '../../../data/repositories/attendance_group_repository.dart';

class InvitesInboxScreen extends StatefulWidget {
  const InvitesInboxScreen({
    super.key,
    required this.repository,
    this.initialInviteId,
  });

  final AttendanceGroupRepository repository;
  final String? initialInviteId;

  @override
  State<InvitesInboxScreen> createState() => _InvitesInboxScreenState();
}

class _InvitesInboxScreenState extends State<InvitesInboxScreen> {
  late Future<List<GroupInvite>> _future;
  StreamSubscription<List<GroupInvite>>? _subscription;
  bool _processingLink = false;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getMyPendingInvites();
    _subscription = widget.repository.watchMyPendingInvites().listen((invites) {
      if (mounted) setState(() => _future = Future.value(invites));
    });
    if (widget.initialInviteId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _acceptDeepLink());
    }
  }

  Future<void> _acceptDeepLink() async {
    if (_processingLink) return;
    setState(() => _processingLink = true);
    try {
      final invite = (await widget.repository.getMyPendingInvites())
          .where((item) => item.id == widget.initialInviteId)
          .firstOrNull;
      await widget.repository.acceptInvite(widget.initialInviteId!);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Joined')));
        context.go('/groups/${invite?.groupId ?? ''}');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This invite is no longer valid.')));
      }
    } finally {
      if (mounted) setState(() => _processingLink = false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.repository.getMyPendingInvites());
    await _future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Group invites')),
        body: FutureBuilder<List<GroupInvite>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done ||
                _processingLink) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _refresh);
            }
            final invites = snapshot.data ?? const [];
            if (invites.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 220),
                    Center(child: Text('No pending invites')),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: invites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _InviteCard(
                  invite: invites[index],
                  repository: widget.repository,
                  onChanged: _refresh,
                ),
              ),
            );
          },
        ),
      );
}

class _InviteCard extends StatefulWidget {
  const _InviteCard({
    required this.invite,
    required this.repository,
    required this.onChanged,
  });
  final GroupInvite invite;
  final AttendanceGroupRepository repository;
  final Future<void> Function() onChanged;

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      if (accept) {
        await widget.repository.acceptInvite(widget.invite.id);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Joined')));
          context.go('/groups/${widget.invite.groupId}');
        }
      } else {
        await widget.repository.declineInvite(widget.invite.id);
        await widget.onChanged();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not respond: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.invite.groupName ?? 'Attendance group',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(widget.invite.eventTitle ?? 'Event',
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 5),
            Text('${widget.invite.invitedByName ?? 'Someone'} invited you',
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _respond(false),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _respond(true),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Accept'),
                ),
              ),
            ]),
          ]),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
      );
}
