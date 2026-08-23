import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/social_repository.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    required this.socialRepository,
  });

  final SocialRepository socialRepository;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<UserProfileCard> _following = [];
  List<UserProfileCard> _followers = [];
  List<UserProfileCard> _friends = [];
  List<UserProfileCard> _searchResults = [];
  bool _loading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSocialLists();
  }

  Future<void> _loadSocialLists() async {
    setState(() => _loading = true);
    final following = await widget.socialRepository.getFollowing();
    final followers = await widget.socialRepository.getFollowers();
    final friends = await widget.socialRepository.getFriends();
    if (mounted) {
      setState(() {
        _following = following;
        _followers = followers;
        _friends = friends;
        _loading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await widget.socialRepository.searchUsers(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
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
            Tab(text: 'Friends (${_friends.length})'),
            Tab(text: 'Following (${_following.length})'),
            Tab(text: 'Followers (${_followers.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Search people by name...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.purple),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            if (_isSearching && _searchController.text.trim().isNotEmpty)
              Expanded(child: _buildUserList(_searchResults, isSearch: true))
            else if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(_friends, emptyMsg: 'No mutual friends yet. Follow users back to become friends!'),
                    _buildUserList(_following, emptyMsg: 'You are not following anyone yet.'),
                    _buildUserList(_followers, emptyMsg: 'No followers yet.'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserProfileCard> users, {String emptyMsg = 'No users found.', bool isSearch = false}) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _shareInvite,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Invite Friends to Future Times'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purple.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipOval(
              child: user.avatarUrl != null
                  ? Image.network(user.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(user.displayName))
                  : _avatarFallback(user.displayName),
            ),
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          subtitle: user.isFriend
              ? const Text('🤝 Mutual Friend', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700, fontSize: 12))
              : null,
          trailing: SizedBox(
            height: 34,
            child: user.isFollowing
                ? OutlinedButton(
                    onPressed: () async {
                      await widget.socialRepository.unfollowUser(user.userId);
                      _loadSocialLists();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Following', style: TextStyle(fontSize: 12)),
                  )
                : FilledButton(
                    onPressed: () async {
                      await widget.socialRepository.followUser(user.userId);
                      _loadSocialLists();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: AppColors.purple,
                    ),
                    child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
          ),
        );
      },
    );
  }

  Widget _avatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w900, fontSize: 17),
      ),
    );
  }

  Future<void> _shareInvite() async {
    const text = 'Join me on Future Times Events to discover live concerts, sports, and festivals near you!\n\nhttps://futuretimesevents.com/invite';
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Join Future Times Events',
      ),
    );
  }
}
