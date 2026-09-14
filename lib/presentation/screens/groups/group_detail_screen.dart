import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/attendance_group.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/attendance_group_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/social_repository.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupRepository,
    required this.authRepository,
    required this.socialRepository,
    required this.eventRepository,
  });

  final String groupId;
  final AttendanceGroupRepository groupRepository;
  final AuthRepository authRepository;
  final SocialRepository socialRepository;
  final EventRepository eventRepository;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<AttendanceGroup?> _groupFuture;
  late Future<List<AttendanceGroupMember>> _membersFuture;
  late Future<List<GroupExpense>> _expensesFuture;
  StreamSubscription<List<AttendanceGroupMember>>? _membersSubscription;
  List<AttendanceGroupMember> _members = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _groupFuture = widget.groupRepository.getGroup(widget.groupId);
    _membersFuture = widget.groupRepository.getMembers(widget.groupId);
    _expensesFuture = widget.groupRepository.getExpenses(widget.groupId);
    _membersSubscription =
        widget.groupRepository.watchMembers(widget.groupId).listen((members) {
      if (mounted) setState(() => _members = members);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _membersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _groupFuture = widget.groupRepository.getGroup(widget.groupId);
      _membersFuture = widget.groupRepository.getMembers(widget.groupId);
      _expensesFuture = widget.groupRepository.getExpenses(widget.groupId);
    });
    await Future.wait([_groupFuture, _membersFuture, _expensesFuture]);
  }

  bool _isHost(AttendanceGroup group) =>
      group.createdBy == widget.authRepository.user?.id;

  @override
  Widget build(BuildContext context) => FutureBuilder<AttendanceGroup?>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _ErrorScaffold(
              message: snapshot.hasError
                  ? 'Could not load this group.'
                  : 'This group is no longer available.',
              onRetry: _refresh,
            );
          }
          final group = snapshot.data!;
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(group.name),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenu(value, group),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _isHost(group) ? 'delete' : 'leave',
                      child:
                          Text(_isHost(group) ? 'Delete group' : 'Leave group'),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.purple,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Chat'),
                    Tab(text: 'Expenses'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _OverviewTab(group: group, isHost: _isHost(group)),
                      _ChatTab(
                        groupId: group.id,
                        repository: widget.groupRepository,
                        authRepository: widget.authRepository,
                      ),
                      _ExpensesTab(
                        groupId: group.id,
                        repository: widget.groupRepository,
                        members: _members,
                        expensesFuture: _expensesFuture,
                        onChanged: _refresh,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Future<void> _handleMenu(String value, AttendanceGroup group) async {
    final action =
        value == 'delete' ? 'Delete this group?' : 'Leave this group?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text(value == 'delete'
            ? 'All group messages and membership will be removed.'
            : 'You can be invited again later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(value == 'delete' ? 'Delete' : 'Leave')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (value == 'delete') {
        await widget.groupRepository.deleteGroup(group.id);
      } else {
        await widget.groupRepository.leaveGroup(group.id);
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Action failed: $error')));
      }
    }
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.group, required this.isHost});
  final AttendanceGroup group;
  final bool isHost;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<AttendanceGroupMember>>(
        future: context
            .findAncestorStateOfType<_GroupDetailScreenState>()!
            ._membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              _EventCard(group: widget.group),
              const SizedBox(height: 12),
              _MeetingCard(
                group: widget.group,
                editable: widget.isHost,
                onEdit: () => _editGroup(context),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: Text('Members',
                        style: Theme.of(context).textTheme.titleLarge)),
                Text('${members.length}',
                    style: const TextStyle(color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 8),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (members.isEmpty)
                const Text('No members yet.',
                    style: TextStyle(color: AppColors.textMuted))
              else
                ...members.map((member) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _Avatar(
                          name: member.displayName ?? 'Member',
                          url: member.avatarUrl),
                      title: Text(member.displayName ?? 'Member'),
                      subtitle: Chip(
                        label: Text(member.role),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: member.role == 'host'
                            ? AppColors.purple.withValues(alpha: .12)
                            : AppColors.surfaceMuted,
                      ),
                      onTap: () => context.push('/user/${member.userId}'),
                    )),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push(
                    '/ride/book?groupId=${widget.group.id}&eventId=${widget.group.eventId}'),
                icon: const Icon(Icons.directions_car_rounded),
                label: const Text('Book shared ride'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showInvites(context),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Invite friends'),
              ),
            ],
          );
        },
      );

  Future<void> _showInvites(BuildContext context) async {
    final repository = context
        .findAncestorStateOfType<_GroupDetailScreenState>()!
        .widget
        .groupRepository;
    final social = context
        .findAncestorStateOfType<_GroupDetailScreenState>()!
        .widget
        .socialRepository;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _InviteSheet(
        socialRepository: social,
        onInvite: (id) =>
            repository.inviteUser(groupId: widget.group.id, invitedUserId: id),
      ),
    );
  }

  Future<void> _editGroup(BuildContext context) async {
    final state = context.findAncestorStateOfType<_GroupDetailScreenState>()!;
    final name = TextEditingController(text: widget.group.name);
    final point = TextEditingController(text: widget.group.meetingPoint ?? '');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit group'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Group name')),
          TextField(
              controller: point,
              decoration: const InputDecoration(labelText: 'Meeting point')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (save == true && name.text.trim().isNotEmpty) {
      await state.widget.groupRepository.updateGroup(
        groupId: widget.group.id,
        name: name.text.trim(),
        meetingPoint: point.text.trim(),
      );
      await state._refresh();
    }
    name.dispose();
    point.dispose();
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.group});
  final AttendanceGroup group;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_GroupDetailScreenState>()!;
    return FutureBuilder<EventModel>(
      future: state.widget.eventRepository.getEventById(group.eventId),
      builder: (context, snapshot) {
        final event = snapshot.data;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.event_rounded, color: AppColors.purple),
            title: Text(event?.name.text ?? 'Event'),
            subtitle: Text(
                event == null ? 'Loading event…' : event.venue?.name ?? ''),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: event == null
                ? null
                : () => context.push('/event/${event.id}', extra: event),
          ),
        );
      },
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard(
      {required this.group, required this.editable, required this.onEdit});
  final AttendanceGroup group;
  final bool editable;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasMap = group.meetingLat != null && group.meetingLng != null;
    return Card(
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.place_rounded, color: AppColors.purple),
          title: Text(group.meetingPoint ?? 'Meeting point not set'),
          subtitle: Text(group.meetingTime == null
              ? 'Meeting time not set'
              : DateFormat.yMMMd()
                  .add_jm()
                  .format(group.meetingTime!.toLocal())),
          trailing: editable
              ? IconButton(
                  onPressed: onEdit, icon: const Icon(Icons.edit_rounded))
              : null,
        ),
        if (hasMap)
          SizedBox(
            height: 150,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(group.meetingLat!, group.meetingLng!),
                  initialZoom: 14,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'za.co.futuretimes.events',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(group.meetingLat!, group.meetingLng!),
                      width: 45,
                      height: 45,
                      child: const Icon(Icons.location_on_rounded,
                          color: AppColors.purple, size: 42),
                    ),
                  ]),
                ],
              ),
            ),
          ),
      ]),
    );
  }
}

class _ChatTab extends StatefulWidget {
  const _ChatTab({
    required this.groupId,
    required this.repository,
    required this.authRepository,
  });
  final String groupId;
  final AttendanceGroupRepository repository;
  final AuthRepository authRepository;

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.repository.sendMessage(groupId: widget.groupId, body: body);
      _controller.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not send message: $error')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<GroupMessage>>(
        stream: widget.repository.watchMessages(widget.groupId),
        builder: (context, snapshot) {
          final messages = (snapshot.data ?? const []).reversed.toList();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
          return Column(children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('Say hi to the group'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (_, index) => _MessageBubble(
                          message: messages[index],
                          own: messages[index].senderId ==
                              widget.authRepository.user?.id),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration:
                          const InputDecoration(hintText: 'Message the group'),
                    ),
                  ),
                  IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_rounded,
                          color: AppColors.purple)),
                ]),
              ),
            ),
          ]);
        },
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.own});
  final GroupMessage message;
  final bool own;

  @override
  Widget build(BuildContext context) => Align(
        alignment: own ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: own ? AppColors.purple : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                own ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!own)
                Text(message.senderDisplayName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(message.body,
                  style: TextStyle(color: own ? Colors.white : AppColors.text)),
              const SizedBox(height: 3),
              Text(_relative(message.createdAt),
                  style: TextStyle(
                      color: own ? Colors.white70 : AppColors.textMuted,
                      fontSize: 11)),
            ],
          ),
        ),
      );
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({
    required this.groupId,
    required this.repository,
    required this.members,
    required this.expensesFuture,
    required this.onChanged,
  });
  final String groupId;
  final AttendanceGroupRepository repository;
  final List<AttendanceGroupMember> members;
  final Future<List<GroupExpense>> expensesFuture;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<GroupExpense>>(
        future: expensesFuture,
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? const [];
          final total =
              expenses.fold<double>(0, (sum, item) => sum + item.amount);
          final share =
              members.isEmpty ? 0.0 : total / members.length.toDouble();
          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _addExpense(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add expense'),
            ),
            body: snapshot.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _Metric(label: 'Total spent', value: total),
                              _Metric(label: 'Your share', value: share),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Bookkeeping only — no money movement.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                      if (expenses.isEmpty)
                        const Center(child: Text('No expenses yet.'))
                      else
                        ...expenses.map((expense) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.receipt_long_rounded),
                              title: Text(expense.description),
                              subtitle: Text(
                                  '${expense.paidByName} · ${DateFormat.yMMMd().format(expense.createdAt.toLocal())}'),
                              trailing: Text(
                                  '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                            )),
                    ],
                  ),
          );
        },
      );

  Future<void> _addExpense(BuildContext context) async {
    final description = TextEditingController();
    final amount = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add expense'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description')),
          TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (save != true) {
      description.dispose();
      amount.dispose();
      return;
    }
    final value = double.tryParse(amount.text);
    if (description.text.trim().isEmpty || value == null || value <= 0) return;
    try {
      await repository.addExpense(
          groupId: groupId, description: description.text, amount: value);
      onChanged();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add expense: $error')));
      }
    } finally {
      description.dispose();
      amount.dispose();
    }
  }
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.socialRepository, required this.onInvite});
  final SocialRepository socialRepository;
  final Future<void> Function(String userId) onInvite;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  late Future<List<dynamic>> _users;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _users = _load('');
  }

  Future<List<dynamic>> _load(String query) async {
    final following = await widget.socialRepository.getFollowing();
    final friends = await widget.socialRepository.getFriends();
    final combined = <String, dynamic>{
      for (final user in [...following, ...friends]) user.userId: user,
    }.values.toList();
    if (query.trim().isEmpty) return combined;
    return combined
        .where((user) => user.displayName
            .toString()
            .toLowerCase()
            .contains(query.trim().toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .7,
            child: Column(children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Invite friends',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _users = _load(value)),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search friends'),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _users,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users = snapshot.data ?? const [];
                    if (users.isEmpty) {
                      return const Center(child: Text('No friends to invite'));
                    }
                    return ListView(
                      children: users
                          .map((user) => ListTile(
                                leading: _Avatar(
                                    name: user.displayName,
                                    url: user.avatarUrl),
                                title: Text(user.displayName),
                                trailing: IconButton(
                                  icon: const Icon(Icons.person_add_rounded),
                                  onPressed: () async {
                                    await widget.onInvite(user.userId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text('Invite sent')));
                                    }
                                  },
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        backgroundImage: url == null ? null : NetworkImage(url!),
        child: url == null
            ? Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase())
            : null,
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
      ]);
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Attendance group')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}

String _relative(DateTime date) {
  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}
