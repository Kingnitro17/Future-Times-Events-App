import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../services/roles/role_service.dart';

const _roleLabels = <String, String>{
  'user': 'User',
  'organizer': 'Organizer',
  'super_admin': 'Super admin',
};

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
    required this.authRepository,
    required this.adminRepository,
  });

  final AuthRepository authRepository;
  final AdminRepository adminRepository;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<bool> _accessFuture;
  late Future<List<Map<String, dynamic>>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _search = '';
  String? _roleFilter;
  String? _busyUserId;

  @override
  void initState() {
    super.initState();
    final userId = widget.authRepository.user?.id;
    _accessFuture = userId == null
        ? Future.value(false)
        : RoleService.instance.isSuperAdmin(userId);
    _usersFuture = _fetch();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetch() =>
      widget.adminRepository.getUsers(search: _search, roleFilter: _roleFilter);

  Future<void> _refresh() async {
    setState(() => _usersFuture = _fetch());
    await _usersFuture;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _search = value;
        _usersFuture = _fetch();
      });
    });
  }

  Future<void> _changeRole(Map<String, dynamic> user, String role) async {
    final id = user['id']?.toString();
    if (id == null || id.isEmpty) return;
    final name = _displayName(user);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change role'),
        content: Text('Make $name a ${_roleLabels[role]?.toLowerCase()}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Change')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyUserId = id);
    try {
      await widget.adminRepository.setUserRole(id, role);
      if (!mounted) return;
      setState(() {
        _usersFuture = _usersFuture.then((rows) => rows
            .map((row) =>
                row['id']?.toString() == id ? {...row, 'role': role} : row)
            .toList());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name is now a ${_roleLabels[role]}')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not change role: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyUserId = null);
    }
  }

  static String _displayName(Map<String, dynamic> user) {
    final name = user['display_name']?.toString();
    if (name != null && name.trim().isNotEmpty) return name;
    final email = user['email']?.toString();
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Unnamed user';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _accessFuture,
      builder: (context, accessSnapshot) {
        if (accessSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()));
        }
        if (accessSnapshot.data != true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/profile');
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Redirecting to your profile...')),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Users')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _roleFilter == null,
                      onSelected: () => setState(() {
                        _roleFilter = null;
                        _usersFuture = _fetch();
                      }),
                    ),
                    for (final entry in _roleLabels.entries)
                      _FilterChip(
                        label: entry.value,
                        selected: _roleFilter == entry.key,
                        onSelected: () => setState(() {
                          _roleFilter = entry.key;
                          _usersFuture = _fetch();
                        }),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _usersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: 'Could not load users.\n${snapshot.error}',
                        onRetry: _refresh,
                      );
                    }
                    final users = snapshot.data ?? const [];
                    if (users.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Text('No users match this filter.',
                                  style: TextStyle(color: AppColors.textMuted)),
                            ),
                          ],
                        ),
                      );
                    }
                    final currentUserId = widget.authRepository.user?.id;
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final id = user['id']?.toString();
                          return _UserTile(
                            user: user,
                            name: _displayName(user),
                            busy: _busyUserId == id,
                            isSelf: id != null && id == currentUserId,
                            onRoleSelected: (role) => _changeRole(user, role),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(),
        ),
      );
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.name,
    required this.busy,
    required this.isSelf,
    required this.onRoleSelected,
  });

  final Map<String, dynamic> user;
  final String name;
  final bool busy;
  final bool isSelf;
  final ValueChanged<String> onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final role = user['role']?.toString() ?? 'user';
    final email = user['email']?.toString();
    final joined = DateTime.tryParse(user['created_at']?.toString() ?? '');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0x147222E3),
        child: Text(
          name.characters.first.toUpperCase(),
          style: const TextStyle(
              color: AppColors.purple, fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        [
          if (email != null && email.isNotEmpty) email,
          if (joined != null)
            'Joined ${DateFormat('MMM d, yyyy').format(joined.toLocal())}',
        ].join('\n'),
        style: const TextStyle(fontSize: 12),
      ),
      isThreeLine: email != null && joined != null,
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RoleBadge(role: role),
                if (!isSelf)
                  PopupMenuButton<String>(
                    tooltip: 'Change role',
                    onSelected: onRoleSelected,
                    itemBuilder: (context) => [
                      for (final entry in _roleLabels.entries)
                        PopupMenuItem<String>(
                          value: entry.key,
                          enabled: entry.key != role,
                          child: Text(entry.value),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'super_admin' => AppColors.error,
      'organizer' => AppColors.purple,
      _ => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _roleLabels[role] ?? role,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
