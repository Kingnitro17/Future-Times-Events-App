import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/social_repository.dart';

class OrganizersScreen extends StatefulWidget {
  const OrganizersScreen({
    super.key,
    required this.socialRepository,
  });

  final SocialRepository socialRepository;

  @override
  State<OrganizersScreen> createState() => _OrganizersScreenState();
}

class _OrganizersScreenState extends State<OrganizersScreen> {
  List<OrganizerModel> _organizers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await widget.socialRepository.getAllOrganizers();
    if (mounted) {
      setState(() {
        _organizers = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Organizers & Hosts'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : _organizers.isEmpty
                ? const Center(
                    child: Text(
                      'No organizers found.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _organizers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final org = _organizers[index];
                      return Material(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/organizer/${org.id}', extra: org),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.purple.withValues(alpha: 0.1),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ClipOval(
                                    child: org.logoUrl != null
                                        ? Image.network(org.logoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _logoFallback(org.name))
                                        : _logoFallback(org.name),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              org.name,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (org.isVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.verified_rounded, color: AppColors.purple, size: 16),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${org.followersCount} followers • ${org.location ?? "Zimbabwe"}',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 34,
                                  child: org.isFollowing
                                      ? OutlinedButton(
                                          onPressed: () async {
                                            await widget.socialRepository.unfollowUser(org.id);
                                            _load();
                                          },
                                          child: const Text('Following', style: TextStyle(fontSize: 12)),
                                        )
                                      : FilledButton(
                                          onPressed: () async {
                                            await widget.socialRepository.followUser(org.id);
                                            _load();
                                          },
                                          style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
                                          child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _logoFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'O';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(color: AppColors.purple, fontWeight: FontWeight.w900, fontSize: 18),
      ),
    );
  }
}
