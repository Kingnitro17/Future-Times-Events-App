import 'package:supabase_flutter/supabase_flutter.dart';

class RoleService {
  RoleService._internal() : _client = Supabase.instance.client;

  static final RoleService _instance = RoleService._internal();

  static RoleService get instance => _instance;

  factory RoleService() => _instance;

  final SupabaseClient _client;
  final Map<String, String> _roles = <String, String>{};

  String? cachedRole(String userId) => _roles[userId];

  Future<String> getRole(String userId) async {
    final cachedRole = _roles[userId];
    if (cachedRole != null) {
      return cachedRole;
    }

    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      final role = row?['role']?.toString() ?? 'user';
      _roles[userId] = role;
      return role;
    } catch (_) {
      return 'user';
    }
  }

  Future<void> refreshRole(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      _roles[userId] = row?['role']?.toString() ?? 'user';
    } catch (_) {
      _roles[userId] = 'user';
    }
  }

  void setRole(String userId, String role) {
    _roles[userId] = role;
  }

  void clear() {
    _roles.clear();
  }

  Future<bool> isOrganizer(String userId) async {
    final role = await getRole(userId);
    return role == 'organizer' || role == 'super_admin';
  }

  Future<bool> isSuperAdmin(String userId) async {
    final role = await getRole(userId);
    return role == 'super_admin';
  }
}
