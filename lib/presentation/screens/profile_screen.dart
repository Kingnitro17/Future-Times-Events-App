import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../data/models/social_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/saved_events_repository.dart';
import '../../data/repositories/discovery_preferences_repository.dart';
import '../../data/repositories/social_repository.dart';
import '../../data/repositories/notification_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authRepository,
    required this.savedEventsRepository,
    required this.preferencesRepository,
    required this.socialRepository,
    required this.notificationRepository,
  });

  final AuthRepository authRepository;
  final SavedEventsRepository savedEventsRepository;
  final DiscoveryPreferencesRepository preferencesRepository;
  final SocialRepository socialRepository;
  final NotificationRepository notificationRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _submitting = false;
  String? _error;
  SocialStats _socialStats = const SocialStats();

  @override
  void initState() {
    super.initState();
    widget.authRepository.addListener(_changed);
    _loadStats();
  }

  void _changed() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        _loadStats();
      }
    });
  }

  Future<void> _loadStats() async {
    if (!widget.authRepository.isSignedIn) return;
    try {
      final stats = await widget.socialRepository.getSocialStats();
      if (mounted) {
        setState(() {
          _socialStats = stats;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _socialStats = const SocialStats();
        });
      }
    }
  }

  @override
  void dispose() {
    widget.authRepository.removeListener(_changed);
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submitAuth({required bool isSignUp}) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (isSignUp) {
        await widget.authRepository.signUp(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
        );
      } else {
        await widget.authRepository.signIn(
          email: _email.text,
          password: _password.text,
        );
      }
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authRepository;
    final content = _buildProfileContent(auth);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: () => context.push('/onboarding'),
            tooltip: 'Discovery Preferences',
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(AuthRepository auth) {
    if (auth.isLoading || (auth.isSignedIn && auth.profileLoading)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isSignedIn) return _buildSignedOut();

    final showFallback = auth.profile == null || auth.profileError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFallback) _buildCachedProfileWarning(auth.profileError),
        _buildSignedIn(auth),
      ],
    );
  }

  Widget _buildCachedProfileWarning(String? detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.deepOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail == null || detail.isEmpty
                  ? 'Displaying cached profile data.'
                  : 'Displaying cached profile data. $detail',
              style: const TextStyle(
                color: Colors.deepOrange,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. RESTORE SIGNED-OUT PROFILE (Browsing Mode) ───────────────────────────

  Widget _buildSignedOut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0ECFF), Color(0xFFFFEFF9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.18)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x180A0A14),
                  blurRadius: 24,
                  offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Image.asset(
                      'assets/images/appicon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.stars_rounded,
                        color: AppColors.purple,
                        size: 40,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('Browsing mode',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Unlock the full Future Times experience',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign up to save events, see friends attending, manage tickets, follow organizers and keep your preferences synced.',
                style: TextStyle(
                    color: AppColors.textSecondary, height: 1.45, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // PRIMARY CTA: Sign Up (Future Times gradient)
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _showSignIn(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Secondary CTA: Sign In
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: _showSignIn,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                    side: const BorderSide(color: AppColors.purple),
                  ),
                  child: const Text('Sign In',
                      style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Preview Unlocked Features
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'PREVIEW WHAT YOU UNLOCK',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2),
          ),
        ),

        _buildGroup([
          _buildRow(Icons.confirmation_number_outlined, 'My Tickets',
              'Access active and past ticket QR codes', _showSignIn),
          _buildRow(Icons.favorite_border_rounded, 'Saved Events',
              'Shortlist events you want to attend', _showSignIn),
          _buildRow(Icons.people_outline_rounded, 'Friends',
              'See which friends are going to live events', _showSignIn),
          _buildRow(Icons.groups_outlined, "Who's Going",
              'Discover attendees and RSVP to events', _showSignIn),
          _buildRow(
              Icons.tune_rounded,
              'Interests',
              '${widget.preferencesRepository.interests.length} selected interests',
              () => context.push('/onboarding')),
          _buildRow(Icons.verified_outlined, 'Organizers I Follow',
              'Stay updated on new event hosts', _showSignIn),
          _buildRow(Icons.notifications_none_rounded, 'Notifications',
              'Get updates on tickets and followers', _showSignIn),
        ]),
      ],
    );
  }

  // ── 2. REAL SIGNED-IN PROFILE ───────────────────────────────────────────────

  Widget _buildSignedIn(AuthRepository auth) {
    final currentUser =
        Supabase.instance.client.auth.currentUser ?? auth.user;
    final metadata = currentUser?.userMetadata ?? const <String, dynamic>{};
    final email = currentUser?.email ?? auth.displayEmail;
    final name = auth.profile?['display_name']?.toString() ??
        metadata['display_name']?.toString() ??
        metadata['full_name']?.toString() ??
        (email.isNotEmpty ? email.split('@').first : 'User');
    final avatarUrl = auth.profile?['avatar_url']?.toString();
    final city = widget.preferencesRepository.city.isEmpty
        ? 'Zimbabwe'
        : widget.preferencesRepository.city;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Identity Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0C0A0A14),
                  blurRadius: 16,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.purple.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.purple, width: 2),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl.trim().isNotEmpty
                          ? Image.network(avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarInitial(name))
                          : _avatarInitial(name),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: AppColors.purple),
                            const SizedBox(width: 2),
                            Text(
                              city,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editName(name),
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.purple),
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Compact Social Stats Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Events', '${_socialStats.eventsAttended}'),
                  _statItem('Following', '${_socialStats.followingCount}',
                      onTap: () => context.push('/friends')),
                  _statItem('Followers', '${_socialStats.followersCount}',
                      onTap: () => context.push('/friends')),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ACCOUNT
        _sectionHeader('ACCOUNT'),
        _buildGroup([
          _buildRow(Icons.edit_outlined, 'Edit Profile',
              'Update display name and avatar', () => _editName(name)),
          _buildRow(
              Icons.confirmation_number_outlined,
              'My Tickets',
              'View active and past event tickets',
              () => context.go('/tickets')),
          _buildRow(
              Icons.favorite_border_rounded,
              'Saved Events',
              'Your shortlist for what happens next',
              () => context.push('/saved')),
        ]),

        const SizedBox(height: 20),

        // SOCIAL
        _sectionHeader('SOCIAL'),
        _buildGroup([
          _buildRow(
              Icons.people_outline_rounded,
              'Friends & Connections',
              'Mutual friends, following and followers',
              () => context.push('/friends')),
          _buildRow(Icons.verified_outlined, 'Organizers You Follow',
              'Event hosts and organizers', () => context.push('/organizers')),
        ]),

        const SizedBox(height: 20),

        // PREFERENCES
        _sectionHeader('PREFERENCES'),
        _buildGroup([
          _buildRow(
              Icons.tune_rounded,
              'Interests & Location',
              '${widget.preferencesRepository.city} · ${widget.preferencesRepository.interests.length} interests',
              () => context.push('/onboarding')),
          _buildRow(
              Icons.notifications_none_rounded,
              'Notifications',
              'Ticket status, updates and follower alerts',
              () => context.push('/notifications')),
        ]),

        const SizedBox(height: 20),

        // SUPPORT
        _sectionHeader('SUPPORT'),
        _buildGroup([
          _buildRow(Icons.help_outline_rounded, 'Help & Support',
              'Get help with tickets and account access', _emailSupport),
          _buildRow(
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'How Future Times protects your information',
              () => _openWeb('/privacy-policy')),
          _buildRow(Icons.description_outlined, 'Terms of Service',
              'Platform terms and conditions', () => _openWeb('/terms')),
          _buildRow(Icons.info_outline_rounded, 'About Future Times Events',
              'Version 1.0.0+1', () {}),
        ]),

        const SizedBox(height: 20),

        // SESSION
        _sectionHeader('SESSION'),
        _buildGroup([
          _buildRow(Icons.logout_rounded, 'Sign Out', 'Log out of your account',
              () async {
            await auth.signOut();
          }, isDestructive: true),
        ]),
      ],
    );
  }

  Widget _statItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _avatarInitial(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
            color: AppColors.purple, fontWeight: FontWeight.w900, fontSize: 24),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildGroup(List<Widget> rows) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
      IconData icon, String title, String subtitle, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : AppColors.purple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isDestructive ? Colors.red : AppColors.purple, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: isDestructive ? Colors.red : AppColors.text,
        ),
      ),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: isDestructive ? Colors.red : AppColors.textMuted),
    );
  }

  Future<void> _showSignIn([bool initialSignUp = false]) =>
      _showAuthModal(isSignUp: initialSignUp);

  Future<void> _showAuthModal({bool isSignUp = false}) async {
    setState(() => _error = null);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              0,
              22,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isSignUp ? 'Create your Account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSignUp
                        ? 'Connect with events, friends, and organizers.'
                        : 'Sign in to access tickets, saved events, and friends.',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (isSignUp) ...[
                    TextField(
                      controller: _displayName,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Full name / Display name',
                        hintText: 'e.g. Tariro Moyo',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      hintText: 'name@example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submitAuth(isSignUp: isSignUp),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText:
                          isSignUp ? 'At least 6 characters' : 'Enter password',
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () => _submitAuth(isSignUp: isSignUp),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Text(
                        _submitting
                            ? (isSignUp ? 'Creating account…' : 'Signing in…')
                            : (isSignUp ? 'Create Account' : 'Sign In'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _error = null);
                        setSheetState(() => isSignUp = !isSignUp);
                      },
                      child: Text(
                        isSignUp
                            ? 'Already have an account? Sign In'
                            : 'New to Future Times? Create Account',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editName(String current) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    try {
      await widget.authRepository.updateDisplayName(value);
      _loadStats();
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  Future<void> _openWeb(String path) async {
    final uri = Uri.https('futuretimesevents.com', path);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this page.')));
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@futuretimesevents.com',
      queryParameters: {'subject': 'Future Times app support'},
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email support@futuretimesevents.com for help.')));
    }
  }
}
