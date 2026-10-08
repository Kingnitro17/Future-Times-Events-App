import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/friends_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/glass_card.dart';
import '../widgets/common/premium_avatar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    this.friendsRepository,
    required this.socialRepository,
  });

  final FriendsRepository? friendsRepository;
  final SocialRepository socialRepository;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final FriendsRepository _repository;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _following = const [];
  List<Map<String, dynamic>> _followers = const [];
  List<Map<String, dynamic>> _friends = const [];
  bool _loading = true;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _repository = widget.friendsRepository ?? FriendsRepository();
    _tabController = TabController(length: 3, vsync: this);
    _refresh();
  }

  Future<void> _refresh() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _repository.getFollowing(userId),
        _repository.getFollowers(userId),
        _repository.getFriends(userId),
      ]);
      if (!mounted) return;
      setState(() {
        _following = results[0];
        _followers = results[1];
        _friends = results[2];
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _followTarget(String targetId) async {
    final previousFollowing = _following;
    final previousFollowers = _followers;
    final previousFriends = _friends;
    final target = _followers.firstWhere(
      (person) => person['id']?.toString() == targetId,
      orElse: () => {
          'id': targetId,
          'display_name': 'User',
          'avatar_url': null,
          'city': null,
          'is_mutual': false,
        },
    );
    setState(() {
      _following = [..._following, {...target, 'is_mutual': false}];
      _friends = _friends.where((person) => person['id']?.toString() != targetId).toList();
    });
    try {
      HapticFeedback.selectionClick();
      await _repository.follow(targetId: targetId);
      await _refresh();
    } catch (_) {
      setState(() {
        _following = previousFollowing;
        _followers = previousFollowers;
        _friends = previousFriends;
      });
    }
  }

  Future<void> _unfollowTarget(String targetId) async {
    final previousFollowing = _following;
    final previousFollowers = _followers;
    final previousFriends = _friends;
    setState(() {
      _following = _following.where((person) => person['id']?.toString() != targetId).toList();
      _friends = _friends.where((person) => person['id']?.toString() != targetId).toList();
    });
    try {
      HapticFeedback.selectionClick();
      await _repository.unfollow(targetId: targetId);
      await _refresh();
    } catch (_) {
      setState(() {
        _following = previousFollowing;
        _followers = previousFollowers;
        _friends = previousFriends;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;
    if (userId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Friends')),
        body: const Center(
          child: Text('Sign in to view your friends.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Friends & Connections'),
        actions: [
          IconButton(
            onPressed: _shareInvite,
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invite Friends',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.purple,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.purple,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Following (${_following.length})'),
            Tab(text: 'Followers (${_followers.length})'),
            Tab(text: 'Friends (${_friends.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                readOnly: true,
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Search people by name...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.purple),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      data: _following,
                      emptyTitle: "You're not following anyone yet",
                      emptyMessage: 'Start connecting with people you know.',
                      trailingBuilder: (person) => OutlinedButton(
                        onPressed: () => _unfollowTarget(person['id']?.toString() ?? ''),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.purple,
                          side: const BorderSide(color: AppColors.purple),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Unfollow'),
                      ),
                    ),
                    _buildList(
                      data: _followers,
                      emptyTitle: 'No followers yet — share your profile',
                      emptyMessage: 'Your social presence will show up here.',
                      trailingBuilder: (person) {
                        final isFollowing = _following.any(
                          (user) => user['id']?.toString() == person['id']?.toString(),
                        );
                        if (isFollowing) {
                          return OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text('Following'),
                          );
                        }
                        return FilledButton(
                          onPressed: () => _followTarget(person['id']?.toString() ?? ''),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text('Follow back'),
                        );
                      },
                    ),
                    _buildList(
                      data: _friends,
                      emptyTitle: 'No mutual follows yet — follow someone who follows you',
                      emptyMessage: 'When you both follow each other, they appear here.',
                      trailingBuilder: (person) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const IconButton(
                            onPressed: null,
                            tooltip: 'Messaging coming soon',
                            icon: Icon(Icons.message_outlined),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _unfollowTarget(person['id']?.toString() ?? ''),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.purple,
                              side: const BorderSide(color: AppColors.purple),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Unfollow'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList({
    required List<Map<String, dynamic>> data,
    required String emptyTitle,
    required String emptyMessage,
    required Widget Function(Map<String, dynamic>) trailingBuilder,
  }) {
    if (data.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final person = data[index];
        final id = person['id']?.toString() ?? '';
        final displayName = person['display_name']?.toString() ?? 'User';
        final city = person['city']?.toString();
        final avatarUrl = person['avatar_url']?.toString();

        return GestureDetector(
          onTap: () => context.push('/user/$id'),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                PremiumAvatar(
                  imageUrl: avatarUrl,
                  initials: displayName,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (city != null && city.trim().isNotEmpty)
                        Text(
                          city,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                trailingBuilder(person),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareInvite() async {
    const text =
        'Join me on Future Times Events to discover live concerts, sports, and festivals near you!\n\nhttps://futuretimesevents.com/invite';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Join Future Times Events',
      ),
    );
  }
}
